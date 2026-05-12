const dns = require('dns');
// Set DNS server to Google Public DNS
dns.setServers(['8.8.8.8', '8.8.4.4']);

dns.resolveSrv('_mongodb._tcp.cluster0.qnzxsgd.mongodb.net', (err, addresses) => {
  if (err) {
    console.error('DNS SRV Resolution Error with 8.8.8.8:', err);
  } else {
    console.log('DNS SRV Resolution Success with 8.8.8.8:', addresses);
  }
});
