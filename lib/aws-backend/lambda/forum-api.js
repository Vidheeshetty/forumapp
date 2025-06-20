const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

const dynamodb = new AWS.DynamoDB.DocumentClient();
const POSTS_TABLE = process.env.POSTS_TABLE;
const COMMENTS_TABLE = process.env.COMMENTS_TABLE;
const USERS_TABLE = process.env.USERS_TABLE;

exports.handler = async (event) => {
    const { httpMethod, path, body, requestContext } = event;
    const userId = requestContext.authorizer?.claims?.sub;

    try {
        switch (`${httpMethod} ${path}`) {
            case 'GET /posts':
                return await getPosts(event.queryStringParameters);
            case 'POST /posts':
                return await createPost(JSON.parse(body), userId);
            case 'POST /posts/{id}/vote':
                return await votePost(event.pathParameters.id, JSON.parse(body), userId);
            case 'GET /posts/{id}/comments':
                return await getComments(event.pathParameters.id);
            case 'POST /posts/{id}/comments':
                return await addComment(event.pathParameters.id, JSON.parse(body), userId);
            case 'GET /users/online':
                return await getOnlineUsers();
            case 'PUT /posts/{id}/pin':
                return await pinPost(event.pathParameters.id, JSON.parse(body));
            case 'PUT /posts/{id}/lock':
                return await lockPost(event.pathParameters.id, JSON.parse(body));
            case 'DELETE /posts/{id}':
                return await deletePost(event.pathParameters.id);
            default:
                return {
                    statusCode: 404,
                    body: JSON.stringify({ error: 'Route not found' })
                };
        }
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
};

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

async function addComment(postId, commentData, userId) {
    const comment = {
        id: uuidv4(),
        postId: postId,
        content: commentData.content,
        parentId: commentData.parentId || null,
        authorId: userId,
        authorName: await getUserName(userId),
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

async function getUserName(userId) {
    try {
        const result = await dynamodb.get({
            TableName: USERS_TABLE,
            Key: { id: userId }
        }).promise();

        return result.Item?.username || 'Anonymous';
    } catch (error) {
        return 'Anonymous';
    }
} getPosts(queryParams = {}) {
    const params = {
        TableName: POSTS_TABLE,
        FilterExpression: 'isApproved = :approved',
        ExpressionAttributeValues: {
            ':approved': true
        }
    };

    const result = await dynamodb.scan(params).promise();

    return {
        statusCode: 200,
        body: JSON.stringify(result.Items.sort((a, b) =>
            new Date(b.createdAt) - new Date(a.createdAt)
        ))
    };
}

async function createPost(postData, userId) {
    const post = {
        id: uuidv4(),
        title: postData.title,
        content: postData.content,
        tags: postData.tags || [],
        authorId: userId,
        authorName: await getUserName(userId),
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

    const post = await dynamodb.get({
        TableName: POSTS_TABLE,
        Key: { id: postId }
    }).promise();

    if (!post.Item) {
        return {
            statusCode: 404,
            body: JSON.stringify({ error: 'Post not found' })
        };
    }

    let { upvotes, downvotes, upvotedBy = [], downvotedBy = [] } = post.Item;

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

async function