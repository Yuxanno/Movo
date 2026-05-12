const dns = require('dns');
dns.resolveSrv('_mongodb._tcp.cluster0.qnzxsgd.mongodb.net', (err, addresses) => {
  if (err) {
    console.error('DNS SRV Resolution Error:', err);
  } else {
    console.log('DNS SRV Resolution Success:', addresses);
  }
});
