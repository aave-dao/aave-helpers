# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [2.2.0](https://github.com/bgd-labs/aave-helpers/compare/v2.1.0...v2.2.0) (2023-02-22)


### Features

* added few methods to gov helpers ([#54](https://github.com/bgd-labs/aave-helpers/issues/54)) ([fd8f23f](https://github.com/bgd-labs/aave-helpers/commit/fd8f23fe701324d202599e3255fd7d52fb611321))
* emit logs ([#56](https://github.com/bgd-labs/aave-helpers/issues/56)) ([c8ef834](https://github.com/bgd-labs/aave-helpers/commit/c8ef8348647a33a38562ba35892366afde0d93b4))

## [2.1.0](https://github.com/bgd-labs/aave-helpers/compare/v2.0.0...v2.1.0) (2023-02-14)


### Features

* add listing engines to helpers ([#52](https://github.com/bgd-labs/aave-helpers/issues/52)) ([b063743](https://github.com/bgd-labs/aave-helpers/commit/b063743a0b206a0e2cf073740ea2d94e4cc4cb6e))
* report diffing `diffReports` ([#48](https://github.com/bgd-labs/aave-helpers/issues/48)) ([ca99238](https://github.com/bgd-labs/aave-helpers/commit/ca992385b8542254494463ca005603b42f9f1119))


### Bug Fixes

* enforce non zero targets on executor ([#47](https://github.com/bgd-labs/aave-helpers/issues/47)) ([23fb586](https://github.com/bgd-labs/aave-helpers/commit/23fb58612dc7b08829a137983577c85b919581a7))

## [2.0.0](https://github.com/bgd-labs/aave-helpers/compare/v1.6.0...v2.0.0) (2023-02-02)


### ⚠ BREAKING CHANGES

* - gov helpers no longer re-exports addresses, fetch them from address-book instead (https://github.com/bgd-labs/aave-address-book/blob/main/src/AaveGovernanceV2.sol)
- `createProposal` was renamed to `createTestProposal`
- the new `createProposal` is intended to be used for actual proposal creation and enforces delegatecall style proposals

### Features

* add implementation snapshots to v3 configurationSnapshots ([#43](https://github.com/bgd-labs/aave-helpers/issues/43)) ([e10aa98](https://github.com/bgd-labs/aave-helpers/commit/e10aa98d42b5cafa862671fee189e0d54a2fddfa))


* !feat: proposal creation helpers (#42) ([13a9871](https://github.com/bgd-labs/aave-helpers/commit/13a987167450a65fe27d9df940628c26b6780b33)), closes [#42](https://github.com/bgd-labs/aave-helpers/issues/42)

## [1.6.0](https://github.com/bgd-labs/aave-helpers/compare/v1.5.0...v1.6.0) (2023-01-31)


### Features

* v2 test base ([#40](https://github.com/bgd-labs/aave-helpers/issues/40)) ([2643d4f](https://github.com/bgd-labs/aave-helpers/commit/2643d4f07cc9fd669d780851705fb4d243a60a9d))


### Bug Fixes

* downgrade scripts ([#38](https://github.com/bgd-labs/aave-helpers/issues/38)) ([8d5c922](https://github.com/bgd-labs/aave-helpers/commit/8d5c922296a82991d93676475cf3d9c9952ed7e1)), closes [#37](https://github.com/bgd-labs/aave-helpers/issues/37)
* use correct minimum version ([#37](https://github.com/bgd-labs/aave-helpers/issues/37)) ([1d1d286](https://github.com/bgd-labs/aave-helpers/commit/1d1d2864f1abda6582c315dff1bce3062cc38a14))

## [1.5.0](https://github.com/bgd-labs/aave-helpers/compare/v1.4.0...v1.5.0) (2023-01-26)


### Features

* add generic executor ([#34](https://github.com/bgd-labs/aave-helpers/issues/34)) ([8f5f9d3](https://github.com/bgd-labs/aave-helpers/commit/8f5f9d3e3b9bbf09cf90625d0f568f0025724f68))

## [1.4.0](https://github.com/bgd-labs/aave-helpers/compare/v1.2.3...v1.4.0) (2023-01-19)


### Features

* add 3_0_1 snapshot ([#32](https://github.com/bgd-labs/aave-helpers/issues/32)) ([3a17bb9](https://github.com/bgd-labs/aave-helpers/commit/3a17bb9ec62f30ce14126e6585d8a66c27ded5e0))
* added TestWithExecutor contract to GovHelpers ([5449659](https://github.com/bgd-labs/aave-helpers/commit/5449659a6599af29d367e3753acfb056747f53a3))


### Bug Fixes

* add _clone() of ReserveConfig for _findReserveConfigBySymbol() and _findReserveConfig() ([#27](https://github.com/bgd-labs/aave-helpers/issues/27)) ([043e0cc](https://github.com/bgd-labs/aave-helpers/commit/043e0cc275882f44410bedd56f0d173c254e403c))

## [1.3.0](https://github.com/bgd-labs/aave-helpers/compare/v1.2.3...v1.3.0) (2023-01-19)


### Features

* added TestWithExecutor contract to GovHelpers ([5449659](https://github.com/bgd-labs/aave-helpers/commit/5449659a6599af29d367e3753acfb056747f53a3))


### Bug Fixes

* add _clone() of ReserveConfig for _findReserveConfigBySymbol() and _findReserveConfig() ([#27](https://github.com/bgd-labs/aave-helpers/issues/27)) ([043e0cc](https://github.com/bgd-labs/aave-helpers/commit/043e0cc275882f44410bedd56f0d173c254e403c))

### [1.2.5](https://github.com/bgd-labs/aave-helpers/compare/v1.2.3...v1.2.5) (2023-01-18)


### Bug Fixes

* add _clone() of ReserveConfig for _findReserveConfigBySymbol() and _findReserveConfig() ([#27](https://github.com/bgd-labs/aave-helpers/issues/27)) ([043e0cc](https://github.com/bgd-labs/aave-helpers/commit/043e0cc275882f44410bedd56f0d173c254e403c))

### [1.2.4](https://github.com/bgd-labs/aave-helpers/compare/v1.2.3...v1.2.4) (2023-01-17)

### [1.2.3](https://github.com/bgd-labs/aave-helpers/compare/v1.2.2...v1.2.3) (2022-12-22)

### [1.2.2](https://github.com/bgd-labs/aave-helpers/compare/v1.2.1...v1.2.2) (2022-12-22)

### [1.2.1](https://github.com/bgd-labs/aave-helpers/compare/v1.2.0...v1.2.1) (2022-12-21)

## [1.2.0](https://github.com/bgd-labs/aave-helpers/compare/v1.1.0...v1.2.0) (2022-12-10)


### Features

* add bridge executor helper ([#6](https://github.com/bgd-labs/aave-helpers/issues/6)) ([c370d02](https://github.com/bgd-labs/aave-helpers/commit/c370d021d365c3a0a52c8022e0dc83f5bd656bc9))
* add findReserveConfigBySymbol ([6ce8276](https://github.com/bgd-labs/aave-helpers/commit/6ce82762b37f39d9ed1c13d96d4da3aafb0d3fa1))
* add helper for fetching current implementation ([#17](https://github.com/bgd-labs/aave-helpers/issues/17)) ([2118f43](https://github.com/bgd-labs/aave-helpers/commit/2118f43a4c1d6eb1f27aaa36e2a703288d40569d))
* add missing governance methods ([#10](https://github.com/bgd-labs/aave-helpers/issues/10)) ([7de5219](https://github.com/bgd-labs/aave-helpers/commit/7de52196667e7f411d3c5ba403138948451a1dee))
* add repay method ([#14](https://github.com/bgd-labs/aave-helpers/issues/14)) ([e00fd13](https://github.com/bgd-labs/aave-helpers/commit/e00fd1381616c2373acf74e2f30aec467d1b7468))
* extend AaveTestBase v3 ([#12](https://github.com/bgd-labs/aave-helpers/issues/12)) ([8ee6ee7](https://github.com/bgd-labs/aave-helpers/commit/8ee6ee727e0c0a6970a4171b1b51bc3cc0b2f727))
* protocol test ([#11](https://github.com/bgd-labs/aave-helpers/issues/11)) ([80379df](https://github.com/bgd-labs/aave-helpers/commit/80379dfd60e9b205c0b42e741a9ecc9fc24de072))
* use governance from address book DRY ([#16](https://github.com/bgd-labs/aave-helpers/issues/16)) ([eebcded](https://github.com/bgd-labs/aave-helpers/commit/eebcded1684bb0feed13fb01f4d9bd9fd42c0618))


### Bug Fixes

* allow supplying user ([dc78ec0](https://github.com/bgd-labs/aave-helpers/commit/dc78ec0931d0151f4f936b7fe2bddb003885d3bd))
* improve e2e test ([#15](https://github.com/bgd-labs/aave-helpers/issues/15)) ([0e7a51a](https://github.com/bgd-labs/aave-helpers/commit/0e7a51afbc174efcf9a037a4a24c14dd162e36eb))
* updated constants to actual address ([#18](https://github.com/bgd-labs/aave-helpers/issues/18)) ([6d13520](https://github.com/bgd-labs/aave-helpers/commit/6d1352014561faeea5039be35c9b6de24e709e31))

## 1.1.0 (2022-08-02)


### Features

* add main entry point for helpers ([#4](https://github.com/bgd-labs/aave-helpers/issues/4)) ([76217c4](https://github.com/bgd-labs/aave-helpers/commit/76217c48de701501a0d9887e6e9b7153159dc31b))
* governance and proxy helpers ([37884c8](https://github.com/bgd-labs/aave-helpers/commit/37884c8d853af8eba5d592c8c5f35010b2161aaa))


### Bug Fixes

* fix goverannce helper ([38d6284](https://github.com/bgd-labs/aave-helpers/commit/38d6284dec1fd24413fefb8e7ae1c1a70df50966))
