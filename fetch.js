const { encodeAbiParameters, parseAbiParameters } = require('viem');

var args = process.argv.slice(2);

async function fetchParams() {
  const bridgeCall = await (
    await fetch(`https://bridge-api.public.zkevm-test.net/bridges/${args[0]}`)
  ).json();
  const deposit = bridgeCall.deposits[bridgeCall.deposits.length - 1];
  const proof = await (
    await fetch(
      `https://bridge-api.public.zkevm-test.net/merkle-proof?deposit_cnt=${deposit.deposit_cnt}&net_id=${deposit.network_id}`
    )
  ).json();
  const encodedData = encodeAbiParameters(
    parseAbiParameters(
      'bytes32[32] smtProof, uint32 index, bytes32 mainnetExitRoot, bytes32 rollupExitRoot, uint32 originNetwork, address originAddress, uint32 destinationNetwork, address destinationAddress, uint256 amount, bytes metadata'
    ),
    [
      proof.proof.merkle_proof,
      Number(deposit.deposit_cnt),
      proof.proof.main_exit_root,
      proof.proof.rollup_exit_root,
      Number(deposit.orig_net),
      deposit.orig_addr,
      Number(deposit.dest_net),
      deposit.dest_addr,
      Number(deposit.amount),
      deposit.metadata,
    ]
  );
  console.log(encodedData);
}

fetchParams();
