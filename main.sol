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
    uint256 public totalFragmentsMinted;

    bytes32 public constant ARENA_DOMAIN =
        0xe4a7b9c2d1f0e8a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3;

    address private constant TREASURY =
        0x7F3c9A2e1B4d6f8E0a9c2b5D4e7F1A0B3C6d9E2;

    error SoftMoltInvalidTier();
    error SoftMoltCooldownActive();
    error SoftMoltNothingToClaim();
    error SoftMoltCycleLimitReached();
    error SoftMoltUnauthorized();

    event ShellShed(
        address indexed player,
        uint8 tier,
        uint256 riftCycle,
        uint256 fragmentId
    );
    event FragmentClaimed(
        address indexed player,
        uint256 fragmentId,
        uint256 bonusAmount
    );
    event RiftAdvanced(uint256 fromCycle, uint256 toCycle);

    constructor() {
        riftKeeper = msg.sender;
        genesisBlock = block.number;
        riftDuration = 47;
        tierThreshold = 5;
        maxShellsPerCycle = 12;
        arenaSeed = keccak256(
            abi.encodePacked(
                block.chainid,
                block.prevrandao,
                block.timestamp,
                blockhash(block.number - 1),
                "SoftMolt_Carapace_v3"
            )
        );
        activeRiftCycle = 0;
    }

