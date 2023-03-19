const diffler = require('diffler');
const pre = require('./reports/preTestEngineArbV3.json');
const post = require('./reports/postTestEngineArbV3.json');

/**
 * Mutates the content & also returns the mutated content
 * @dev needed due to a bug in foundry json utils
 * @param {*} content
 * @returns
 */
function fixJSON(content) {
  content.reserves = JSON.parse(
    content.reserves.replace(/"{/g, '{').replace(/}"/g, '}').replace(/"/g, '"')
  );
  content.strategies = JSON.parse(
    content.strategies.replace(/"{/g, '{').replace(/}"/g, '}').replace(/"/g, '"')
  );
  content.eModes = JSON.parse(
    content.eModes.replace(/"{/g, '{').replace(/}"/g, '}').replace(/"/g, '"')
  );
  return content;
}

console.log(JSON.stringify(diffler(fixJSON(pre), fixJSON(post)), null, 2));
