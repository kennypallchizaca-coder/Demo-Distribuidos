const http = require('http');
const assert = require('assert');

// Verify server responds with 200 OK
setTimeout(() => {
  http.get('http://127.0.0.1:8080', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      try {
        assert.strictEqual(res.statusCode, 200);
        assert.strictEqual(data, 'OK');
        console.log('✔ Integration tests passed successfully!');
        process.exit(0);
      } catch (e) {
        console.error('✖ Assertion failed:', e.message);
        process.exit(1);
      }
    });
  }).on('error', (err) => {
    console.error('✖ Test failed:', err);
    process.exit(1);
  });
}, 300);
