'use strict';

const express = require('express');
const app = express();

const listen_port = (process.env.SERVERPORT)? Number(process.env.SERVERPORT): 8080;
const listen_addr = '0.0.0.0';

app.get('/*', (req, res) => {

    const r = {
        url: req.url,
        server: {
            addr: req.socket.localAddress,
            port: req.socket.localPort
        },
        client: {
            addr: req.socket.remoteAddress,
            port: req.socket.remotePort
        },
        'x-forwarded-for': req.header('x-forwarded-for') || '',
        'x-real-ip': req.header('x-real-ip') || ''
    };

    if (req.accepts().includes("application/json")) {
        let json = JSON.stringify(r);
        res.contentType('application/json').send(json);
        console.log(`request: ${json}`);
    }
    else {
        res.contentType('text/plain')
            .send(`Client Addr: ${r.client.addr}:${r.client.port}
Server Addr: ${r.server.addr}:${r.server.port}
X-Forwarded-For: ${r['x-forwarded-for']}
X-Real-Ip: ${r['x-real-ip']}\n`);
        console.log(`request: ${JSON.stringify(r)}`);
    }
});

app.listen(listen_port, listen_addr, () => {
    console.log(`test-image started on ${listen_addr}:${listen_port}`);
});
