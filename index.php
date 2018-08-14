<?php
Header("Content-Type: text/plain");
echo "Client Addr: {$_SERVER['REMOTE_ADDR']}:{$_SERVER['REMOTE_PORT']}\n";
echo "Server Addr: {$_SERVER['SERVER_ADDR']}:{$_SERVER['SERVER_PORT']}\n";
