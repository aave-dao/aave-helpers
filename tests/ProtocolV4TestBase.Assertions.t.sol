// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISpoke, IHub, ITokenizationSpoke, ISpokeConfigurator, PositionManagers, IAaveV4ConfigEngine, IGiverPositionManager, ITakerPositionManager, IConfigPositionManager, INativeTokenGateway, ISignatureGateway} from 'aave-address-book/AaveV4.sol';
import {ProtocolV4TestBase} from 'src/ProtocolV4TestBase.sol';
import {MockSpoke, MockOracle, MockRecordingAccessManager} from 'tests/mocks/v4/V4Mocks.sol';

/// @notice Unit coverage for the payload-facing assertions on {ProtocolV4TestBase}, over mocks only.
contract ProtocolV4TestBaseAssertionsTest is ProtocolV4TestBase {
  uint64 internal constant ROLE_ID = 301;
  uint64 internal constant OTHER_ROLE_ID = 302;

  MockRecordingAccessManager internal accessManager;
  MockSpoke internal spoke;
  MockOracle internal oracle;

  address internal target = makeAddr('TARGET');
  address internal referenceTarget = makeAddr('REFERENCE_TARGET');

  function setUp() public {
    accessManager = new MockRecordingAccessManager();

    spoke = new MockSpoke();
    oracle = new MockOracle();
    spoke.setOracle(address(oracle));
    spoke.setAuthority(address(accessManager));
    oracle.setSpoke(address(spoke));
  }

  function test_assertRolesWired_passesWhenWired() public {
    _wire(target, ROLE_ID);

    _assertRolesWired(_roleUpdate(target, ROLE_ID), address(0));
  }

  /// @dev `address(0)` must skip the divergence check rather than compare against address(0)'s roles.
  /// The reference is left unwired, so a non-zero one fails the same call.
  function test_assertRolesWired_skipsDivergenceCheckForZeroReference() public {
    _wire(target, ROLE_ID);

    _assertRolesWired(_roleUpdate(target, ROLE_ID), address(0));

    vm.expectRevert();
    this.assertRolesWired(_roleUpdate(target, ROLE_ID), referenceTarget);
  }

  function test_assertRolesWired_passesWhenReferenceCarriesSameRole() public {
    _wire(target, ROLE_ID);
    _wire(referenceTarget, ROLE_ID);

    _assertRolesWired(_roleUpdate(target, ROLE_ID), referenceTarget);
  }

  function test_assertRolesWired_revertsWhenNotWired() public {
    vm.expectRevert();
    this.assertRolesWired(_roleUpdate(target, ROLE_ID), address(0));
  }

  function test_assertRolesWired_revertsWhenWiredToAnotherRole() public {
    _wire(target, OTHER_ROLE_ID);

    vm.expectRevert();
    this.assertRolesWired(_roleUpdate(target, ROLE_ID), address(0));
  }

  function test_assertRolesWired_revertsWhenReferenceDiverges() public {
    _wire(target, ROLE_ID);
    _wire(referenceTarget, OTHER_ROLE_ID);

    vm.expectRevert();
    this.assertRolesWired(_roleUpdate(target, ROLE_ID), referenceTarget);
  }

  /// @dev The authority is read off the update, so a payload naming the wrong one must fail.
  function test_assertRolesWired_revertsOnWrongAuthority() public {
    _wire(target, ROLE_ID);

    IAaveV4ConfigEngine.TargetFunctionRoleUpdate memory item = _roleUpdate(target, ROLE_ID);
    item.authority = address(new MockRecordingAccessManager());

    vm.expectRevert();
    this.assertRolesWired(item, address(0));
  }

  function test_assertSpokeDeployment_passesWhenWired() public view {
    _assertSpokeDeployment(ISpoke(address(spoke)));
  }

  function test_assertSpokeDeployment_revertsWhenSpokeHasNoCode() public {
    vm.expectRevert();
    this.assertSpokeDeployment(ISpoke(makeAddr('NOT_A_CONTRACT')));
  }

  function test_assertSpokeDeployment_revertsOnAuthorityMismatch() public {
    spoke.setAuthority(makeAddr('OTHER_ACCESS_MANAGER'));

    vm.expectRevert();
    this.assertSpokeDeployment(ISpoke(address(spoke)));
  }

  /// @dev An oracle left unbound, or bound to a different spoke, prices the wrong reserve ids.
  function test_assertSpokeDeployment_revertsWhenOracleNotBoundToSpoke() public {
    oracle.setSpoke(makeAddr('OTHER_SPOKE'));

    vm.expectRevert();
    this.assertSpokeDeployment(ISpoke(address(spoke)));
  }

  function test_assertSpokeDeployment_revertsOnOracleDecimalsMismatch() public {
    oracle.setDecimals(18);

    vm.expectRevert();
    this.assertSpokeDeployment(ISpoke(address(spoke)));
  }

  function test_assertSpokeDeployment_revertsWhenOracleHasNoCode() public {
    spoke.setOracle(makeAddr('NOT_AN_ORACLE'));

    vm.expectRevert();
    this.assertSpokeDeployment(ISpoke(address(spoke)));
  }

  /// @dev External wrappers so the negative cases can catch the assertion failures.
  function assertRolesWired(
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate memory item,
    address referenceTarget_
  ) public view {
    _assertRolesWired(item, referenceTarget_);
  }

  function assertSpokeDeployment(ISpoke spoke_) public view {
    _assertSpokeDeployment(spoke_);
  }

  function _selectors() internal pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](2);
    selectors[0] = ISpoke.addReserve.selector;
    selectors[1] = ISpoke.updateReserveConfig.selector;
    return selectors;
  }

  function _roleUpdate(
    address target_,
    uint64 roleId
  ) internal view returns (IAaveV4ConfigEngine.TargetFunctionRoleUpdate memory) {
    return
      IAaveV4ConfigEngine.TargetFunctionRoleUpdate({
        authority: address(accessManager),
        target: target_,
        selectors: _selectors(),
        roleId: roleId
      });
  }

  function _wire(address target_, uint64 roleId) internal {
    accessManager.setTargetFunctionRole(target_, _selectors(), roleId);
  }

  function _accessManager() internal view override returns (address) {
    return address(accessManager);
  }

  function _spokeConfigurator() internal view override returns (ISpokeConfigurator) {
    return ISpokeConfigurator(address(0));
  }

  function _getHubs() internal view override returns (IHub[] memory) {
    return new IHub[](0);
  }

  function _getSpokes() internal view override returns (ISpoke[] memory) {
    return new ISpoke[](0);
  }

  function _getTokenizationSpokes() internal view override returns (ITokenizationSpoke[] memory) {
    return new ITokenizationSpoke[](0);
  }

  function _getPositionManagers() internal view override returns (PositionManagers memory) {
    return
      PositionManagers({
        giver: IGiverPositionManager(address(0)),
        taker: ITakerPositionManager(address(0)),
        config: IConfigPositionManager(address(0)),
        nativeGateway: INativeTokenGateway(address(0)),
        signatureGateway: ISignatureGateway(address(0))
      });
  }
}
