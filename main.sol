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
        uint256 mintedAt;
        uint256 riftCycle;
        bool claimed;
    }

    struct PlayerState {
        uint256 totalFragments;
        uint256 lastRiftCycle;
        uint256 streakBonus;
    }

    mapping(address => ShellFragment[]) private _playerShells;
    mapping(address => PlayerState) private _playerState;
    mapping(uint256 => uint256) private _cycleFragmentCount;
    uint256 public activeRiftCycle;
