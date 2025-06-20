const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

const dynamodb = new AWS.DynamoDB.DocumentClient();
const POSTS_TABLE = process.env.POSTS_TABLE;
const COMMENTS_TABLE = process.env.COMMENTS_TABLE;
const USERS_TABLE = process.env.USERS_TABLE;

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));

    const { httpMethod, path, body, requestContext, pathParameters } = event;
    const userId = requestContext.authorizer?.claims?.sub;
    const userEmail = requestContext.authorizer?.claims?.email;
    const userName = requestContext.authorizer?.claims?.preferred_username ||
                     requestContext.authorizer?.claims?.email?.split('@')[0] ||
                     'Anonymous';

    // Add CORS headers
    const headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    };

    if (httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }

    try {
        // Create or update user record
        if (userId) {
            await createOrUpdateUser(userId, userName, userEmail);
        }

        let result;
        switch (`${httpMethod} ${getRoutePath(path)}`) {
            case 'GET /posts':
                result = await getPosts(event.queryStringParameters);
                break;
            case 'POST /posts':
                result = await createPost(JSON.parse(body || '{}'), userId, userName);
                break;
            case 'POST /posts/{id}/vote':
                result = await votePost(pathParameters.id, JSON.parse(body || '{}'), userId);
                break;
            case 'GET /posts/{id}/comments':
                result = await getComments(pathParameters.id);
                break;
            case 'POST /posts/{id}/comments':
                result = await addComment(pathParameters.id, JSON.parse(body || '{}'), userId, userName);
                break;
            case 'GET /users/online':
                result = await getOnlineUsers();
                break;
            case 'GET /users/{id}':
                result = await getUser(pathParameters.id);
                break;
            case 'PUT /users/{id}/status':
                result = await updateUserStatus(pathParameters.id, JSON.parse(body || '{}'));
                break;
            case 'PUT /posts/{id}/pin':
                result = await pinPost(pathParameters.id, JSON.parse(body || '{}'));
                break;
            case 'PUT /posts/{id}/lock':
                result = await lockPost(pathParameters.id, JSON.parse(body || '{}'));
                break;
            case 'DELETE /posts/{id}':
                result = await deletePost(pathParameters.id);
                break;
            case 'POST /comments/{id}/vote':
                result = await voteComment(pathParameters.id, JSON.parse(body || '{}'), userId);
                break;
            default:
                result = {
                    statusCode: 404,
                    body: JSON.stringify({ error: 'Route not found', path, method: httpMethod })
                };
        }

        return {
            ...result,
            headers: { ...headers, ...result.headers }
        };
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                error: error.message,
                stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
            })
        };
    }
};

function getRoutePath(path) {
    // Convert /posts/123/comments to /posts/{id}/comments
    return path.replace(/\/[^\/]+/g, (match, offset, string) => {
        const segments = string.split('/');
        const currentSegment = match.slice(1);

        // Check if this looks like an ID (UUID or alphanumeric)
        if (/^[a-zA-Z0-9\-_]+$/.test(currentSegment) && currentSegment.length > 5) {
            return '/{id}';
        }
        return match;
    });
}

async function createOrUpdateUser(userId, userName, userEmail) {
    try {
        const now = new Date().toISOString();

        await dynamodb.put({
            TableName: USERS_TABLE,
            Item: {
                id: userId,
                username: userName,
                email: userEmail,
                lastSeen: now,
                isOnline: true,
                isModerator: false,
                createdAt: now
            }
        }).promise();
    } catch (error) {
        console.error('Error creating/updating user:', error);
    }
}

async function getPosts(queryParams = {}) {
    const params = {
        TableName: POSTS_TABLE,
        FilterExpression: 'isApproved = :approved',
        ExpressionAttributeValues: {
            ':approved': true
        }
    };

    const result = await dynamodb.scan(params).promise();

    const sortedPosts = result.Items.sort((a, b) => {
        // Pin posts to top, then sort by creation date
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return new Date(b.createdAt) - new Date(a.createdAt);
    });

    return {
        statusCode: 200,
        body: JSON.stringify(sortedPosts)
    };
}

async function createPost(postData, userId, userName) {
    if (!postData.title || !postData.content) {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: 'Title and content are required' })
        };
    }

    const post = {
        id: uuidv4(),
        title: postData.title,
        content: postData.content,
        tags: postData.tags || [],
        authorId: userId,
        authorName: userName,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        upvotes: 0,
        downvotes: 0,
        commentCount: 0,
        isPinned: false,
        isLocked: false,
        isApproved: true,
        upvotedBy: [],
        downvotedBy: []
    };

    await dynamodb.put({
        TableName: POSTS_TABLE,
        Item: post
    }).promise();

    return {
        statusCode: 201,
        body: JSON.stringify(post)
    };
}

async function votePost(postId, voteData, userId) {
    const { isUpvote } = voteData;

    const result = await dynamodb.get({
        TableName: POSTS_TABLE,
        Key: { id: postId }
    }).promise();

    if (!result.Item) {
        return {
            statusCode: 404,
            body: JSON.stringify({ error: 'Post not found' })
        };
    }

    let { upvotes, downvotes, upvotedBy = [], downvotedBy = [] } = result.Item;

    // Remove previous vote
    if (upvotedBy.includes(userId)) {
        upvotes--;
        upvotedBy = upvotedBy.filter(id => id !== userId);
    }
    if (downvotedBy.includes(userId)) {
        downvotes--;
        downvotedBy = downvotedBy.filter(id => id !== userId);
    }

    // Add new vote
    if (isUpvote) {
        upvotes++;
        upvotedBy.push(userId);
    } else {
        downvotes++;
        downvotedBy.push(userId);
    }

    await dynamodb.update({
        TableName: POSTS_TABLE,
        Key: { id: postId },
        UpdateExpression: 'SET upvotes = :upvotes, downvotes = :downvotes, upvotedBy = :upvotedBy, downvotedBy = :downvotedBy',
        ExpressionAttributeValues: {
            ':upvotes': upvotes,
            ':downvotes': downvotes,
            ':upvotedBy': upvotedBy,
            ':downvotedBy': downvotedBy
        }
    }).promise();

    return {
        statusCode: 200,
        body: JSON.stringify({ success: true })
    };
}

async function getComments(postId) {
    const params = {
        TableName: COMMENTS_TABLE,
        FilterExpression: 'postId = :postId AND isApproved = :approved',
        ExpressionAttributeValues: {
            ':postId': postId,
            ':approved': true
        }
    };

    const result = await dynamodb.scan(params).promise();

    return {
        statusCode: 200,
        body: JSON.stringify(result.Items.sort((a, b) =>
            new Date(a.createdAt) - new Date(b.createdAt)
        ))
    };
}

async function addComment(postId, commentData, userId, userName) {
    if (!commentData.content) {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: 'Content is required' })
        };
    }

    const comment = {
        id: uuidv4(),
        postId: postId,
        content: commentData.content,
        parentId: commentData.parentId || null,
        authorId: userId,
        authorName: userName,
        createdAt: new Date().toISOString(),
        upvotes: 0,
        downvotes: 0,
        isApproved: true,
        upvotedBy: [],
        downvotedBy: []
    };

    await dynamodb.put({
        TableName: COMMENTS_TABLE,
        Item: comment
    }).promise();

    // Update post comment count
    await dynamodb.update({
        TableName: POSTS_TABLE,
        Key: { id: postId },
        UpdateExpression: 'ADD commentCount :inc',
        ExpressionAttributeValues: {
            ':inc': 1
        }
    }).promise();

    return {
        statusCode: 201,
        body: JSON.stringify(comment)
    };
}

async function voteComment(commentId, voteData, userId) {
    const { isUpvote } = voteData;

    const result = await dynamodb.get({
        TableName: COMMENTS_TABLE,
        Key: { id: commentId }
    }).promise();

    if (!result.Item) {
        return {
            statusCode: 404,
            body: JSON.stringify({ error: 'Comment not found' })
        };
    }

    let { upvotes, downvotes, upvotedBy = [], downvotedBy = [] } = result.Item;

    // Remove previous vote
    if (upvotedBy.includes(userId)) {
        upvotes--;
        upvotedBy = upvotedBy.filter(id => id !== userId);
    }
    if (downvotedBy.includes(userId)) {
        downvotes--;
        downvotedBy = downvotedBy.filter(id => id !== userId);
    }

    // Add new vote
    if (isUpvote) {
        upvotes++;
        upvotedBy.push(userId);
    } else {
        downvotes++;
        downvotedBy.push(userId);
    }

    await dynamodb.update({
        TableName: COMMENTS_TABLE,
        Key: { id: commentId },
        UpdateExpression: 'SET upvotes = :upvotes, downvotes = :downvotes, upvotedBy = :upvotedBy, downvotedBy = :downvotedBy',
        ExpressionAttributeValues: {
            ':upvotes': upvotes,
            ':downvotes': downvotes,
            ':upvotedBy': upvotedBy,
            ':downvotedBy': downvotedBy
        }
    }).promise();

    return {
        statusCode: 200,
        body: JSON.stringify({ success: true })
    };
}

async function getOnlineUsers() {
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();

    const params = {
        TableName: USERS_TABLE,
        FilterExpression: 'lastSeen > :threshold',
        ExpressionAttributeValues: {
            ':threshold': fiveMinutesAgo
        }
    };

    const result = await dynamodb.scan(params).promise();

    return {
        statusCode: 200,
        body: JSON.stringify(result.Items)
    };
}

async function getUser(userId) {
    const result = await dynamodb.get({
        TableName: USERS_TABLE,
        Key: { id: userId }
    }).promise();

    if (!result.Item) {
        return {
            statusCode: 404,
            body: JSON.stringify({ error: 'User not found' })
        };
    }

    return {
        statusCode: 200,
        body: JSON.stringify(result.Item)
    };
}

async function updateUserStatus(userId, statusData) {
    await dynamodb.update({
        TableName: USERS_TABLE,
        Key: { id: userId },
        UpdateExpression: 'SET isOnline = :online, lastSeen = :lastSeen',
        ExpressionAttributeValues: {
            ':online': statusData.isOnline,
            ':lastSeen': statusData.lastSeen || new Date().toISOString()
        }
    }).promise();

    return {
        statusCode: 200,
        body: JSON.stringify({ success: true })
    };
}

async function pinPost(postId, pinData) {
    await dynamodb.update({
        TableName: POSTS_TABLE,
        Key: { id: postId },
        UpdateExpression: 'SET isPinned = :pinned',
        ExpressionAttributeValues: {
            ':pinned': pinData.isPinned
        }
    }).promise();

    return {
        statusCode: 200,
        body: JSON.stringify({ success: true })
    };
}

async function lockPost(postId, lockData) {
    await dynamodb.update({
        TableName: POSTS_TABLE,
        Key: { id: postId },
        UpdateExpression: 'SET isLocked = :locked',
        ExpressionAttributeValues: {
            ':locked': lockData.isLocked
        }
    }).promise();

    return {
        statusCode: 200,
        body: JSON.stringify({ success: true })
    };
}

async function deletePost(postId) {
    await dynamodb.delete({
        TableName: POSTS_TABLE,
        Key: { id: postId }
    }).promise();

    return {
        statusCode: 200,
        body: JSON.stringify({ success: true })
    };
}