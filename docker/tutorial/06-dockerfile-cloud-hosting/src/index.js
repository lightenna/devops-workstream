// content of index.js
const http = require('http');
const env = require('process').env;
require('dotenv').config();
const port = env.PORT || 8080;
// const port = (env.PORT === undefined ? 8080 : env.PORT);

const requestHandler = (request, response) => {
    console.log(request.url);
    response.end('Hello Node.js Server!');
};

const server = http.createServer(requestHandler);

server.listen(port, (err) => {
    if (err) {
        return console.log('something bad happened', err);
    }

    console.log(`server is listening on ${port}`);
});

/**
 * const a = 8 | 16
 * const b = true || false
 * if (true || false) { ... }
 */