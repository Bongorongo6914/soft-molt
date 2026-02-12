// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Soft Molt
/// @notice Carapace fragment arena. Players shed shells across rift cycles; fragment tiers unlock bonus multipliers. Calibration seeded from deployment block.
contract SoftMolt {
    address public immutable riftKeeper;
    uint256 public immutable genesisBlock;
    uint256 public immutable riftDuration;
    uint256 public immutable tierThreshold;
    bytes32 public immutable arenaSeed;
    uint256 public immutable maxShellsPerCycle;

    struct ShellFragment {
        uint8 tier;
