# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [3.0.0](https://github.com/bgd-labs/aave-helpers/compare/v2.3.0...v3.0.0) (2024-07-25)

### ⚠ BREAKING CHANGES

- use aave origin and update to 3.1 (#306)

### Features

- Aave steth withdrawer ([#315](https://github.com/bgd-labs/aave-helpers/issues/315)) ([8f99938](https://github.com/bgd-labs/aave-helpers/commit/8f99938a7384b0faac76d37346e44f68ef0b19f7))
- Add base ccc update payload. ([#305](https://github.com/bgd-labs/aave-helpers/issues/305)) ([2e1710d](https://github.com/bgd-labs/aave-helpers/commit/2e1710decbfcc074804c1f2bd760e228e6442953))
- add base configEngine ([#134](https://github.com/bgd-labs/aave-helpers/issues/134)) ([b5df36c](https://github.com/bgd-labs/aave-helpers/commit/b5df36cc33bfc40db26d62088fc4ba7135bc09de))
- Add Base contracts to generate aDI adapter payloads ([#285](https://github.com/bgd-labs/aave-helpers/issues/285)) ([8ff94a6](https://github.com/bgd-labs/aave-helpers/commit/8ff94a640b0dc72649686357709a6396508f0ea6))
- add buildBase ([#135](https://github.com/bgd-labs/aave-helpers/issues/135)) ([2152246](https://github.com/bgd-labs/aave-helpers/commit/2152246b8a3c1104cf96e83c9b87ffe5f9b8ba69))
- add create2 helpers ([#193](https://github.com/bgd-labs/aave-helpers/issues/193)) ([a690d33](https://github.com/bgd-labs/aave-helpers/commit/a690d33080262a02f87a67fda50fc312242756d2))
- add gov v3 helpers ([#139](https://github.com/bgd-labs/aave-helpers/issues/139)) ([1e1c177](https://github.com/bgd-labs/aave-helpers/commit/1e1c1778f99870deceb2f9f233c74d83ec729aaf))
- Add payload zero checks ([#121](https://github.com/bgd-labs/aave-helpers/issues/121)) ([0480a4b](https://github.com/bgd-labs/aave-helpers/commit/0480a4b549ed543d3d4160b8a956739e1724913b))
- added script for scroll and zkevm ([#211](https://github.com/bgd-labs/aave-helpers/issues/211)) ([6cc788d](https://github.com/bgd-labs/aave-helpers/commit/6cc788d1346e6bcaf8f02878841eb74662c87c17))
- allow bypassing e2e ([#173](https://github.com/bgd-labs/aave-helpers/issues/173)) ([39e1676](https://github.com/bgd-labs/aave-helpers/commit/39e1676f166a53cf195fbe1f29f210e284a14293))
- bnb deploy scripts ([#180](https://github.com/bgd-labs/aave-helpers/issues/180)) ([428dc96](https://github.com/bgd-labs/aave-helpers/commit/428dc96fb23d5858e3c5ecb6bd5e24d236613efc))
- check that address has code ([41c0392](https://github.com/bgd-labs/aave-helpers/commit/41c0392171165f98e4e5f96c2997512a169eb6cb))
- emode category for v3 config engine ([#97](https://github.com/bgd-labs/aave-helpers/issues/97)) ([88ccbc4](https://github.com/bgd-labs/aave-helpers/commit/88ccbc4e18c2469011496b59642ba56d0f4830d9)), closes [#111](https://github.com/bgd-labs/aave-helpers/issues/111)
- execute proposal ([#199](https://github.com/bgd-labs/aave-helpers/issues/199)) ([6dc9101](https://github.com/bgd-labs/aave-helpers/commit/6dc9101c71e7afa85efa1c4989789fff86d29d48))
- expose deterministic helpers ([#197](https://github.com/bgd-labs/aave-helpers/issues/197)) ([2adead7](https://github.com/bgd-labs/aave-helpers/commit/2adead7afb5ee7cfae29bc3cacd91b75aeab028d))
- gnosis deploy scripts ([#156](https://github.com/bgd-labs/aave-helpers/issues/156)) ([1ffe6b1](https://github.com/bgd-labs/aave-helpers/commit/1ffe6b10ba993e1e440312561b091b166d72d732))
- new aave v3 token deal ([#142](https://github.com/bgd-labs/aave-helpers/issues/142)) ([b6bedff](https://github.com/bgd-labs/aave-helpers/commit/b6bedff58ce75fdf4022c91e181d40e3b3faa44e))
- New RPCs ([#179](https://github.com/bgd-labs/aave-helpers/issues/179)) ([70f523f](https://github.com/bgd-labs/aave-helpers/commit/70f523f115045315a5c1e1cd71c88a884e64c850))
- scroll deploy scripts ([#212](https://github.com/bgd-labs/aave-helpers/issues/212)) ([bd1002b](https://github.com/bgd-labs/aave-helpers/commit/bd1002b320c9e585de5f8691f3468f2471a96579))
- snapshot collateralManager ([#172](https://github.com/bgd-labs/aave-helpers/issues/172)) ([a4676d2](https://github.com/bgd-labs/aave-helpers/commit/a4676d29ce2e017ffa6d89da51d1eeb545f555b7))
- support create2 args ([#264](https://github.com/bgd-labs/aave-helpers/issues/264)) ([f429c55](https://github.com/bgd-labs/aave-helpers/commit/f429c55b999c8cff5333e239cc5aec2c551e15fe))
- support more chains ([#132](https://github.com/bgd-labs/aave-helpers/issues/132)) ([89c591c](https://github.com/bgd-labs/aave-helpers/commit/89c591c66fecee33698eaa05e76b7fc8359e72c7))
- test full 2.5 flow ([#162](https://github.com/bgd-labs/aave-helpers/issues/162)) ([76b0fac](https://github.com/bgd-labs/aave-helpers/commit/76b0fac11d6b75ef70752cc46e7c8eed5af0d655))
- use aave origin and update to 3.1 ([#306](https://github.com/bgd-labs/aave-helpers/issues/306)) ([acf9575](https://github.com/bgd-labs/aave-helpers/commit/acf95756729255f2f08ea440b00a8394ed610cfb))
- use different create2 ([#150](https://github.com/bgd-labs/aave-helpers/issues/150)) ([4c084bf](https://github.com/bgd-labs/aave-helpers/commit/4c084bff9fb3fe7f92e7ba71b0b594957166ea53))
- v2 default test ([#154](https://github.com/bgd-labs/aave-helpers/issues/154)) ([f6a905a](https://github.com/bgd-labs/aave-helpers/commit/f6a905a6c2b2f4e1fd00c30d4f5f86ea275756e9))
- validate payload execution < block.gaslimit in defaultTest ([#290](https://github.com/bgd-labs/aave-helpers/issues/290)) ([6567dae](https://github.com/bgd-labs/aave-helpers/commit/6567dae5143253858eeff93a8de4bd8c0563f353))
- zkevm scripts ([#213](https://github.com/bgd-labs/aave-helpers/issues/213)) ([07f2682](https://github.com/bgd-labs/aave-helpers/commit/07f26829ae0a00c21c00d29f28c635cf2fbb45db))

### Bug Fixes

- add buffer for block gas limit ([#292](https://github.com/bgd-labs/aave-helpers/issues/292)) ([31ee364](https://github.com/bgd-labs/aave-helpers/commit/31ee36457e84e41cc1d328cd923d226557c3fa10))
- add missing helper for scroll and zkevm ([#215](https://github.com/bgd-labs/aave-helpers/issues/215)) ([0d01980](https://github.com/bgd-labs/aave-helpers/commit/0d01980340f61d6ff81343b79cf6142d09ceb669))
- add more snapshots ([#119](https://github.com/bgd-labs/aave-helpers/issues/119)) ([a17aeb9](https://github.com/bgd-labs/aave-helpers/commit/a17aeb9eddb3c26d9c95d580baa883fbccb3c9d3))
- Add payload already created check to createPayload method ([#296](https://github.com/bgd-labs/aave-helpers/issues/296)) ([a574110](https://github.com/bgd-labs/aave-helpers/commit/a574110bf9b0f5a2c9efcd8cc66c8f05200baeb1))
- align cli versions ([#165](https://github.com/bgd-labs/aave-helpers/issues/165)) ([78e58db](https://github.com/bgd-labs/aave-helpers/commit/78e58dbd37f2d879313587dea0d2cd783aadade3))
- allow one off error on repay ([#144](https://github.com/bgd-labs/aave-helpers/issues/144)) ([743c0fb](https://github.com/bgd-labs/aave-helpers/commit/743c0fbfcf8231b5fb420a72d7b6424d26ef7d59))
- blocknumber for tests ([#191](https://github.com/bgd-labs/aave-helpers/issues/191)) ([216c880](https://github.com/bgd-labs/aave-helpers/commit/216c880096bb84b41035d5538c1abe5cbc119944))
- bnb naming ([#282](https://github.com/bgd-labs/aave-helpers/issues/282)) ([ffdfec5](https://github.com/bgd-labs/aave-helpers/commit/ffdfec57ed1b7f90afbcdb108efc1141e91bc479))
- borrow engine require ([#188](https://github.com/bgd-labs/aave-helpers/issues/188)) ([8a04d33](https://github.com/bgd-labs/aave-helpers/commit/8a04d33786d52b658e40e03d0b92d137383dabf7))
- bump aave-cli ([0447d4e](https://github.com/bgd-labs/aave-helpers/commit/0447d4e30d2a6d625bda386b011211c6f05b808a))
- bump address book ([#257](https://github.com/bgd-labs/aave-helpers/issues/257)) ([07ad879](https://github.com/bgd-labs/aave-helpers/commit/07ad879a8afb0f693e49fb4bdc6a7ef13d426c04))
- bump address-book ([7da64a6](https://github.com/bgd-labs/aave-helpers/commit/7da64a6c8dfac96578d99b4f59c221a5f79e463b))
- config engine payload bnb ([#181](https://github.com/bgd-labs/aave-helpers/issues/181)) ([cb11211](https://github.com/bgd-labs/aave-helpers/commit/cb11211b4df83d369438cf4a36bccce19bc28fbd))
- createPayload method made internal so that it can be broadcasted ([#298](https://github.com/bgd-labs/aave-helpers/issues/298)) ([2f7c3c9](https://github.com/bgd-labs/aave-helpers/commit/2f7c3c9c2609c5d3f2b9df1de2c9f11ac445eb1a))
- don't queue on govv2 when trying to execute payload via short ([#234](https://github.com/bgd-labs/aave-helpers/issues/234)) ([11ae64b](https://github.com/bgd-labs/aave-helpers/commit/11ae64bec0bbfd167a83deb840317c8c873cacba))
- e2e ethereum mainnet ([#140](https://github.com/bgd-labs/aave-helpers/issues/140)) ([9ca17b6](https://github.com/bgd-labs/aave-helpers/commit/9ca17b6ecd99c1fe6209e944713fe6293ad37b4f))
- fix typos ([#254](https://github.com/bgd-labs/aave-helpers/issues/254)) ([63eb8fa](https://github.com/bgd-labs/aave-helpers/commit/63eb8fa8d06286a11bc19bf17cbcb1fd6b8dba10))
- foundry breaking changes ([#127](https://github.com/bgd-labs/aave-helpers/issues/127)) ([be96d3e](https://github.com/bgd-labs/aave-helpers/commit/be96d3ee4f43e5b9b6adec90b0bce85ab33dce0b))
- losen version of aave-cli ([93c334c](https://github.com/bgd-labs/aave-helpers/commit/93c334c6d7dcde7abfbfc3222c1f143c84fc6f0c))
- make irs compatible with stateful irs ([#262](https://github.com/bgd-labs/aave-helpers/issues/262)) ([0050f31](https://github.com/bgd-labs/aave-helpers/commit/0050f319b5773f9e0741128b6b342018eac4f6b5))
- only do selectFork when fork is different ([#163](https://github.com/bgd-labs/aave-helpers/issues/163)) ([33f350c](https://github.com/bgd-labs/aave-helpers/commit/33f350cba2857cdd5ec921ca3a4fce1e7e2f1eba))
- patch deal2 prank ([#230](https://github.com/bgd-labs/aave-helpers/issues/230)) ([6881c76](https://github.com/bgd-labs/aave-helpers/commit/6881c76494c4baa4d5c3cdcea00fab4bac05d13c))
- patch ir import ([#275](https://github.com/bgd-labs/aave-helpers/issues/275)) ([5446518](https://github.com/bgd-labs/aave-helpers/commit/5446518a5e5a22a0d649305f8dd05d099c1aea55))
- patch usdc ([#203](https://github.com/bgd-labs/aave-helpers/issues/203)) ([5481ac5](https://github.com/bgd-labs/aave-helpers/commit/5481ac5ca51c76f87dec0ef316942c51f10515dc))
- patch usdc & supply cap tests ([#208](https://github.com/bgd-labs/aave-helpers/issues/208)) ([1adaebd](https://github.com/bgd-labs/aave-helpers/commit/1adaebd6fe409770e3a2d56560e0127df85b3e2e))
- pin-version ([#149](https://github.com/bgd-labs/aave-helpers/issues/149)) ([b07db13](https://github.com/bgd-labs/aave-helpers/commit/b07db131e5068b22d05629b718dfa12283c4a10c))
- properly reverse iterate ([#216](https://github.com/bgd-labs/aave-helpers/issues/216)) ([45cc9e8](https://github.com/bgd-labs/aave-helpers/commit/45cc9e8edf8374d5f32cccea2de24e1267da719b))
- rely on local npm installation ([#171](https://github.com/bgd-labs/aave-helpers/issues/171)) ([2111f26](https://github.com/bgd-labs/aave-helpers/commit/2111f267b9f6d906ae8cbdf7e06dd693bbeff9bb))
- remove \_ and add reference to source ([#190](https://github.com/bgd-labs/aave-helpers/issues/190)) ([abea2a7](https://github.com/bgd-labs/aave-helpers/commit/abea2a703edb9d90291833c4f19f44d2a7e53224))
- remove aave interface link ([#183](https://github.com/bgd-labs/aave-helpers/issues/183)) ([251864a](https://github.com/bgd-labs/aave-helpers/commit/251864a684267dfb34c8d7b29b411f4ea8db38d0))
- remove cap limitation ([#195](https://github.com/bgd-labs/aave-helpers/issues/195)) ([926c817](https://github.com/bgd-labs/aave-helpers/commit/926c817a72b15b10c54566fee443086518870ca1))
- remove duplicated errors ([#148](https://github.com/bgd-labs/aave-helpers/issues/148)) ([f559d58](https://github.com/bgd-labs/aave-helpers/commit/f559d58dc0e40557e06d60675c318a2427a9aded))
- remove tests for old stuff ([#222](https://github.com/bgd-labs/aave-helpers/issues/222)) ([fae3da0](https://github.com/bgd-labs/aave-helpers/commit/fae3da0811f41ecb30da1129976c53d15350b895))
- replace snx whale ([#276](https://github.com/bgd-labs/aave-helpers/issues/276)) ([e716f32](https://github.com/bgd-labs/aave-helpers/commit/e716f32915a2fc1e3b7bf6ccdf913efb8b8ace96))
- snapshot indexes ([#269](https://github.com/bgd-labs/aave-helpers/issues/269)) ([1daafea](https://github.com/bgd-labs/aave-helpers/commit/1daafea0e7f7baafa82d2b386e284e3850abf048))
- snapshot with new interest rates strategy ([#259](https://github.com/bgd-labs/aave-helpers/issues/259)) ([bd87e61](https://github.com/bgd-labs/aave-helpers/commit/bd87e6189222e01cc2ddffb2551e94e06f716a1d))
- update aave address book ([#281](https://github.com/bgd-labs/aave-helpers/issues/281)) ([7c84bd8](https://github.com/bgd-labs/aave-helpers/commit/7c84bd834bfc25e2cb7bda15ca4eb05328a6dde6))
- update aave cli ([#235](https://github.com/bgd-labs/aave-helpers/issues/235)) ([3b4c2ab](https://github.com/bgd-labs/aave-helpers/commit/3b4c2abdef6efb1a984e0e76227c055caca2aa5b))
- update address book with aDI bridge adapter interface ([#260](https://github.com/bgd-labs/aave-helpers/issues/260)) ([9505ee5](https://github.com/bgd-labs/aave-helpers/commit/9505ee51b420265c91912923e00c1b040c594485))
- update for aligned BNB ([b49a36e](https://github.com/bgd-labs/aave-helpers/commit/b49a36e523b1d0c13d361419b937f249f305c72d))
- update forge std etc ([#157](https://github.com/bgd-labs/aave-helpers/issues/157)) ([707ad78](https://github.com/bgd-labs/aave-helpers/commit/707ad78ffd9f58fedd85a029f32ac52ef74af15a))
- update origin repo ([#316](https://github.com/bgd-labs/aave-helpers/issues/316)) ([6dc5580](https://github.com/bgd-labs/aave-helpers/commit/6dc5580361775bcee1c1f40c942c88ac3c8fb38a))
- update tooling ([#279](https://github.com/bgd-labs/aave-helpers/issues/279)) ([d91ff89](https://github.com/bgd-labs/aave-helpers/commit/d91ff89512a10afce868166f90466a9f3ac7af4c))
- updated adi tests. Updated chain ids ([#299](https://github.com/bgd-labs/aave-helpers/issues/299)) ([b645891](https://github.com/bgd-labs/aave-helpers/commit/b645891fb688b37f814940fcc3dc2650fc1ada79))
- updated solidity utils. refactored safeApprove to forceApprove ([#131](https://github.com/bgd-labs/aave-helpers/issues/131)) ([a6f6c89](https://github.com/bgd-labs/aave-helpers/commit/a6f6c894f2cc02914c3d30beb3595945604ef692))
- use create select fork always ([#164](https://github.com/bgd-labs/aave-helpers/issues/164)) ([963cc7b](https://github.com/bgd-labs/aave-helpers/commit/963cc7bab94078dadbf3668696bdd77f51dc65fe))

## [2.3.0](https://github.com/bgd-labs/aave-helpers/compare/v2.2.0...v2.3.0) (2023-06-29)

### Features

- add forwarders ([#72](https://github.com/bgd-labs/aave-helpers/issues/72)) ([49e85e7](https://github.com/bgd-labs/aave-helpers/commit/49e85e78a5a7290271e820dd5c5581384c55402a))
- add oracle info ([#84](https://github.com/bgd-labs/aave-helpers/issues/84)) ([c273eec](https://github.com/bgd-labs/aave-helpers/commit/c273eec190a72ae956102a5f2e1dae892704817c))
- add risk steward ([#83](https://github.com/bgd-labs/aave-helpers/issues/83)) ([1d973c4](https://github.com/bgd-labs/aave-helpers/commit/1d973c4f11f9938c8f97c805716a59de9e94474f))
- add sentinel to snapshot ([#91](https://github.com/bgd-labs/aave-helpers/issues/91)) ([c339e88](https://github.com/bgd-labs/aave-helpers/commit/c339e889982651779b2e94dc94a5b1c9ac5563ba))
- added \_logStrategyPreviewUrlParams() to ProtocolV3TestBase and ProtocolV2TestBase ([#65](https://github.com/bgd-labs/aave-helpers/issues/65)) ([2c62d04](https://github.com/bgd-labs/aave-helpers/commit/2c62d04bb701c3791f9abe354bef66a23ad09a41))
- finalize steward scripts ([#95](https://github.com/bgd-labs/aave-helpers/issues/95)) ([7be8b44](https://github.com/bgd-labs/aave-helpers/commit/7be8b441c667e2dc7a784b45f8a733cd8382687f))
- finalize v2 addresses ([#103](https://github.com/bgd-labs/aave-helpers/issues/103)) ([1371a7c](https://github.com/bgd-labs/aave-helpers/commit/1371a7cca3777d4f3906a21c45477acc024d453b))
- flatten structure ([#75](https://github.com/bgd-labs/aave-helpers/issues/75)) ([8e37485](https://github.com/bgd-labs/aave-helpers/commit/8e37485ff4a4d76e2783a97a2841bab4d0440836))
- forwarder contract for metis ([#86](https://github.com/bgd-labs/aave-helpers/issues/86)) ([8b407ff](https://github.com/bgd-labs/aave-helpers/commit/8b407ff9554ab5e42b5da37dd5ec15cd13eb2244))
- improve e2e testsuite ([#107](https://github.com/bgd-labs/aave-helpers/issues/107)) ([691f48c](https://github.com/bgd-labs/aave-helpers/commit/691f48cad066c5ea3fe924b906d48c557fe80e53))
- improve v3 tests ([#104](https://github.com/bgd-labs/aave-helpers/issues/104)) ([7aebb79](https://github.com/bgd-labs/aave-helpers/commit/7aebb798c214bce19e777069b140fef94eaecb30))
- include name/samybol of asv ([#106](https://github.com/bgd-labs/aave-helpers/issues/106)) ([4c81999](https://github.com/bgd-labs/aave-helpers/commit/4c819998905a1103ea50e4924d56632a6c77f0ac))
- initialize as empty objects ([#87](https://github.com/bgd-labs/aave-helpers/issues/87)) ([89b8e02](https://github.com/bgd-labs/aave-helpers/commit/89b8e02b29897ba765a546e706fb9c2f74c801d7))
- ipfs tools ([#90](https://github.com/bgd-labs/aave-helpers/issues/90)) ([8504b3e](https://github.com/bgd-labs/aave-helpers/commit/8504b3ebbeed210f98563b77202ba4b2a1c3ef37))
- new governance tools ([#99](https://github.com/bgd-labs/aave-helpers/issues/99)) ([cec1bff](https://github.com/bgd-labs/aave-helpers/commit/cec1bff3ec6b80be7757bc40dfdbb886a9d8a99c))
- patch deal (reverting caller) ([#110](https://github.com/bgd-labs/aave-helpers/issues/110)) ([32254d7](https://github.com/bgd-labs/aave-helpers/commit/32254d7305cf4c021620aba3537bbdb015c591cd))
- patch v2 e2e suite ([#92](https://github.com/bgd-labs/aave-helpers/issues/92)) ([d9f4e2d](https://github.com/bgd-labs/aave-helpers/commit/d9f4e2db82863c7e579f8af5904769f0d5894dec))
- rates base payload and factory for v2 ([#68](https://github.com/bgd-labs/aave-helpers/issues/68)) ([ccadc3c](https://github.com/bgd-labs/aave-helpers/commit/ccadc3caead3dde0835a75f0fe148b903a3692a0))
- serialize chainId on v2 as well ([#80](https://github.com/bgd-labs/aave-helpers/issues/80)) ([136abd4](https://github.com/bgd-labs/aave-helpers/commit/136abd46bb8ee55bc6f0cf505a3886ac541aeff0))
- show ipfs preview ([#100](https://github.com/bgd-labs/aave-helpers/issues/100)) ([4c4d223](https://github.com/bgd-labs/aave-helpers/commit/4c4d223940af14b107a1bc14defabfa5c511fea2))
- snapshot symbol & name ([#105](https://github.com/bgd-labs/aave-helpers/issues/105)) ([5d303fe](https://github.com/bgd-labs/aave-helpers/commit/5d303fe0f0c424d8919953269ddf3851f91dccc4))
- update deps ([#79](https://github.com/bgd-labs/aave-helpers/issues/79)) ([0a48f24](https://github.com/bgd-labs/aave-helpers/commit/0a48f2427814777666c05252aaadad208f52f47a))
- update libraries ([#96](https://github.com/bgd-labs/aave-helpers/issues/96)) ([3b01622](https://github.com/bgd-labs/aave-helpers/commit/3b016220a02bb0fe3a7589e666bb6ea7ffdc3cde))
- update-gov-scripts ([#116](https://github.com/bgd-labs/aave-helpers/issues/116)) ([9160727](https://github.com/bgd-labs/aave-helpers/commit/916072715cd641e4fd337ca084836efd259dcdc3))
- upgrade ci ([#109](https://github.com/bgd-labs/aave-helpers/issues/109)) ([d476f42](https://github.com/bgd-labs/aave-helpers/commit/d476f421589e246b5870889a7d0bf75e4b6c3950))
- use lib to read flags instead of doing calls ([#108](https://github.com/bgd-labs/aave-helpers/issues/108)) ([60dd764](https://github.com/bgd-labs/aave-helpers/commit/60dd764f9914ad08230601a8c07b42a30d433d3c))

### Bug Fixes

- 0.8 compat ([#69](https://github.com/bgd-labs/aave-helpers/issues/69)) ([78b55aa](https://github.com/bgd-labs/aave-helpers/commit/78b55aadb671b03cde196673d3524399a21bbf33))
- add missing scripts ([#82](https://github.com/bgd-labs/aave-helpers/issues/82)) ([afe2a9f](https://github.com/bgd-labs/aave-helpers/commit/afe2a9fd060a5a6ff9871f448548e5009e1de6ea))
- bump aave-address-book ([3da36e6](https://github.com/bgd-labs/aave-helpers/commit/3da36e6fdfd6543bb1c6f7b7b2fcc0506015a97c))
- diff-snapshot**s** typo ([#101](https://github.com/bgd-labs/aave-helpers/issues/101)) ([b239952](https://github.com/bgd-labs/aave-helpers/commit/b2399522b7f41477358e61c48eec0dbb2ffbd29f))
- error string not reflecting actual error ([#112](https://github.com/bgd-labs/aave-helpers/issues/112)) ([2ebb620](https://github.com/bgd-labs/aave-helpers/commit/2ebb62097723c2bcb95b4a01c2eff336dae50a6f))
- ethereum e2e ([#98](https://github.com/bgd-labs/aave-helpers/issues/98)) ([cfd9133](https://github.com/bgd-labs/aave-helpers/commit/cfd91334e58b36fdeb0296d3cb8e40a85ed3d954))
- fix linting ([1d24015](https://github.com/bgd-labs/aave-helpers/commit/1d2401543d737dd9aa621b5a8730afa55714fe03))
- resolve slight inconsistency on oracle.DECIMALS ([#89](https://github.com/bgd-labs/aave-helpers/issues/89)) ([0ccea16](https://github.com/bgd-labs/aave-helpers/commit/0ccea1639301700c59db40586cf36f96d08b7457))
- write config to json ([#71](https://github.com/bgd-labs/aave-helpers/issues/71)) ([0a77460](https://github.com/bgd-labs/aave-helpers/commit/0a774604ebf4019a9dc44768e2085a1ea053d6db))

## [2.2.0](https://github.com/bgd-labs/aave-helpers/compare/v2.1.0...v2.2.0) (2023-02-22)

### Features

- added few methods to gov helpers ([#54](https://github.com/bgd-labs/aave-helpers/issues/54)) ([fd8f23f](https://github.com/bgd-labs/aave-helpers/commit/fd8f23fe701324d202599e3255fd7d52fb611321))
- emit logs ([#56](https://github.com/bgd-labs/aave-helpers/issues/56)) ([c8ef834](https://github.com/bgd-labs/aave-helpers/commit/c8ef8348647a33a38562ba35892366afde0d93b4))

## [2.1.0](https://github.com/bgd-labs/aave-helpers/compare/v2.0.0...v2.1.0) (2023-02-14)

### Features

- add listing engines to helpers ([#52](https://github.com/bgd-labs/aave-helpers/issues/52)) ([b063743](https://github.com/bgd-labs/aave-helpers/commit/b063743a0b206a0e2cf073740ea2d94e4cc4cb6e))
- report diffing `diffReports` ([#48](https://github.com/bgd-labs/aave-helpers/issues/48)) ([ca99238](https://github.com/bgd-labs/aave-helpers/commit/ca992385b8542254494463ca005603b42f9f1119))

### Bug Fixes

- enforce non zero targets on executor ([#47](https://github.com/bgd-labs/aave-helpers/issues/47)) ([23fb586](https://github.com/bgd-labs/aave-helpers/commit/23fb58612dc7b08829a137983577c85b919581a7))

## [2.0.0](https://github.com/bgd-labs/aave-helpers/compare/v1.6.0...v2.0.0) (2023-02-02)

### ⚠ BREAKING CHANGES

- - gov helpers no longer re-exports addresses, fetch them from address-book instead (https://github.com/bgd-labs/aave-address-book/blob/main/src/AaveGovernanceV2.sol)

* `createProposal` was renamed to `createTestProposal`
* the new `createProposal` is intended to be used for actual proposal creation and enforces delegatecall style proposals

### Features

- add implementation snapshots to v3 configurationSnapshots ([#43](https://github.com/bgd-labs/aave-helpers/issues/43)) ([e10aa98](https://github.com/bgd-labs/aave-helpers/commit/e10aa98d42b5cafa862671fee189e0d54a2fddfa))

- !feat: proposal creation helpers (#42) ([13a9871](https://github.com/bgd-labs/aave-helpers/commit/13a987167450a65fe27d9df940628c26b6780b33)), closes [#42](https://github.com/bgd-labs/aave-helpers/issues/42)

## [1.6.0](https://github.com/bgd-labs/aave-helpers/compare/v1.5.0...v1.6.0) (2023-01-31)

### Features

- v2 test base ([#40](https://github.com/bgd-labs/aave-helpers/issues/40)) ([2643d4f](https://github.com/bgd-labs/aave-helpers/commit/2643d4f07cc9fd669d780851705fb4d243a60a9d))

### Bug Fixes

- downgrade scripts ([#38](https://github.com/bgd-labs/aave-helpers/issues/38)) ([8d5c922](https://github.com/bgd-labs/aave-helpers/commit/8d5c922296a82991d93676475cf3d9c9952ed7e1)), closes [#37](https://github.com/bgd-labs/aave-helpers/issues/37)
- use correct minimum version ([#37](https://github.com/bgd-labs/aave-helpers/issues/37)) ([1d1d286](https://github.com/bgd-labs/aave-helpers/commit/1d1d2864f1abda6582c315dff1bce3062cc38a14))

## [1.5.0](https://github.com/bgd-labs/aave-helpers/compare/v1.4.0...v1.5.0) (2023-01-26)

### Features

- add generic executor ([#34](https://github.com/bgd-labs/aave-helpers/issues/34)) ([8f5f9d3](https://github.com/bgd-labs/aave-helpers/commit/8f5f9d3e3b9bbf09cf90625d0f568f0025724f68))

## [1.4.0](https://github.com/bgd-labs/aave-helpers/compare/v1.2.3...v1.4.0) (2023-01-19)

### Features

- add 3_0_1 snapshot ([#32](https://github.com/bgd-labs/aave-helpers/issues/32)) ([3a17bb9](https://github.com/bgd-labs/aave-helpers/commit/3a17bb9ec62f30ce14126e6585d8a66c27ded5e0))
- added TestWithExecutor contract to GovHelpers ([5449659](https://github.com/bgd-labs/aave-helpers/commit/5449659a6599af29d367e3753acfb056747f53a3))

### Bug Fixes

- add \_clone() of ReserveConfig for \_findReserveConfigBySymbol() and \_findReserveConfig() ([#27](https://github.com/bgd-labs/aave-helpers/issues/27)) ([043e0cc](https://github.com/bgd-labs/aave-helpers/commit/043e0cc275882f44410bedd56f0d173c254e403c))

## [1.3.0](https://github.com/bgd-labs/aave-helpers/compare/v1.2.3...v1.3.0) (2023-01-19)

### Features

- added TestWithExecutor contract to GovHelpers ([5449659](https://github.com/bgd-labs/aave-helpers/commit/5449659a6599af29d367e3753acfb056747f53a3))

### Bug Fixes

- add \_clone() of ReserveConfig for \_findReserveConfigBySymbol() and \_findReserveConfig() ([#27](https://github.com/bgd-labs/aave-helpers/issues/27)) ([043e0cc](https://github.com/bgd-labs/aave-helpers/commit/043e0cc275882f44410bedd56f0d173c254e403c))

### [1.2.5](https://github.com/bgd-labs/aave-helpers/compare/v1.2.3...v1.2.5) (2023-01-18)

### Bug Fixes

- add \_clone() of ReserveConfig for \_findReserveConfigBySymbol() and \_findReserveConfig() ([#27](https://github.com/bgd-labs/aave-helpers/issues/27)) ([043e0cc](https://github.com/bgd-labs/aave-helpers/commit/043e0cc275882f44410bedd56f0d173c254e403c))

### [1.2.4](https://github.com/bgd-labs/aave-helpers/compare/v1.2.3...v1.2.4) (2023-01-17)

### [1.2.3](https://github.com/bgd-labs/aave-helpers/compare/v1.2.2...v1.2.3) (2022-12-22)

### [1.2.2](https://github.com/bgd-labs/aave-helpers/compare/v1.2.1...v1.2.2) (2022-12-22)

### [1.2.1](https://github.com/bgd-labs/aave-helpers/compare/v1.2.0...v1.2.1) (2022-12-21)

## [1.2.0](https://github.com/bgd-labs/aave-helpers/compare/v1.1.0...v1.2.0) (2022-12-10)

### Features

- add bridge executor helper ([#6](https://github.com/bgd-labs/aave-helpers/issues/6)) ([c370d02](https://github.com/bgd-labs/aave-helpers/commit/c370d021d365c3a0a52c8022e0dc83f5bd656bc9))
- add findReserveConfigBySymbol ([6ce8276](https://github.com/bgd-labs/aave-helpers/commit/6ce82762b37f39d9ed1c13d96d4da3aafb0d3fa1))
- add helper for fetching current implementation ([#17](https://github.com/bgd-labs/aave-helpers/issues/17)) ([2118f43](https://github.com/bgd-labs/aave-helpers/commit/2118f43a4c1d6eb1f27aaa36e2a703288d40569d))
- add missing governance methods ([#10](https://github.com/bgd-labs/aave-helpers/issues/10)) ([7de5219](https://github.com/bgd-labs/aave-helpers/commit/7de52196667e7f411d3c5ba403138948451a1dee))
- add repay method ([#14](https://github.com/bgd-labs/aave-helpers/issues/14)) ([e00fd13](https://github.com/bgd-labs/aave-helpers/commit/e00fd1381616c2373acf74e2f30aec467d1b7468))
- extend AaveTestBase v3 ([#12](https://github.com/bgd-labs/aave-helpers/issues/12)) ([8ee6ee7](https://github.com/bgd-labs/aave-helpers/commit/8ee6ee727e0c0a6970a4171b1b51bc3cc0b2f727))
- protocol test ([#11](https://github.com/bgd-labs/aave-helpers/issues/11)) ([80379df](https://github.com/bgd-labs/aave-helpers/commit/80379dfd60e9b205c0b42e741a9ecc9fc24de072))
- use governance from address book DRY ([#16](https://github.com/bgd-labs/aave-helpers/issues/16)) ([eebcded](https://github.com/bgd-labs/aave-helpers/commit/eebcded1684bb0feed13fb01f4d9bd9fd42c0618))

### Bug Fixes

- allow supplying user ([dc78ec0](https://github.com/bgd-labs/aave-helpers/commit/dc78ec0931d0151f4f936b7fe2bddb003885d3bd))
- improve e2e test ([#15](https://github.com/bgd-labs/aave-helpers/issues/15)) ([0e7a51a](https://github.com/bgd-labs/aave-helpers/commit/0e7a51afbc174efcf9a037a4a24c14dd162e36eb))
- updated constants to actual address ([#18](https://github.com/bgd-labs/aave-helpers/issues/18)) ([6d13520](https://github.com/bgd-labs/aave-helpers/commit/6d1352014561faeea5039be35c9b6de24e709e31))

## 1.1.0 (2022-08-02)

### Features

- add main entry point for helpers ([#4](https://github.com/bgd-labs/aave-helpers/issues/4)) ([76217c4](https://github.com/bgd-labs/aave-helpers/commit/76217c48de701501a0d9887e6e9b7153159dc31b))
- governance and proxy helpers ([37884c8](https://github.com/bgd-labs/aave-helpers/commit/37884c8d853af8eba5d592c8c5f35010b2161aaa))

### Bug Fixes

- fix goverannce helper ([38d6284](https://github.com/bgd-labs/aave-helpers/commit/38d6284dec1fd24413fefb8e7ae1c1a70df50966))
