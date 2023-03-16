const file = require('./reports/postTestEngineArbV3.json');

file.reserves = JSON.parse(
  file.reserves.replace(/"{/g, '{').replace(/}"/g, '}').replace(/"/g, '"')
);
file.strategies = JSON.parse(
  file.strategies.replace(/"{/g, '{').replace(/}"/g, '}').replace(/"/g, '"')
);
file.eModes = JSON.parse(file.eModes.replace(/"{/g, '{').replace(/}"/g, '}').replace(/"/g, '"'));

console.log(JSON.stringify(file, null, 2));
