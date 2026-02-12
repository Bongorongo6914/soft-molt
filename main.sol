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

    function _currentRiftCycle() internal view returns (uint256) {
        return (block.number - genesisBlock) / riftDuration;
    }

    function _advanceRift() internal {
        uint256 cycle = _currentRiftCycle();
        if (cycle > activeRiftCycle) {
            uint256 prev = activeRiftCycle;
            activeRiftCycle = cycle;
            emit RiftAdvanced(prev, cycle);
        }
    }

    function shedShell(uint8 tier) external {
        if (tier == 0 || tier > 4) revert SoftMoltInvalidTier();

        _advanceRift();
        uint256 cycle = activeRiftCycle;

        if (_cycleFragmentCount[cycle] >= maxShellsPerCycle) {
            revert SoftMoltCycleLimitReached();
        }

        PlayerState storage state = _playerState[msg.sender];
        uint256 cooldownEnd = state.lastRiftCycle + 1;
        if (cycle < cooldownEnd && state.totalFragments > 0) {
            revert SoftMoltCooldownActive();
        }

        uint256 fragmentId = _playerShells[msg.sender].length;
        _playerShells[msg.sender].push(
            ShellFragment({
                tier: tier,
                mintedAt: block.number,
                riftCycle: cycle,
                claimed: false
            })
        );

        state.totalFragments += 1;
        uint256 prevCycle = state.lastRiftCycle;
        state.lastRiftCycle = cycle;
        if (prevCycle == cycle - 1 || (prevCycle == 0 && cycle == 0)) {
            state.streakBonus += 1;
        } else {
            state.streakBonus = 1;
        }

        _cycleFragmentCount[cycle] += 1;
        totalFragmentsMinted += 1;

        emit ShellShed(msg.sender, tier, cycle, fragmentId);
    }

    function claimFragment(uint256 fragmentId) external {
        ShellFragment[] storage shells = _playerShells[msg.sender];
        if (fragmentId >= shells.length) revert SoftMoltNothingToClaim();

        ShellFragment storage frag = shells[fragmentId];
        if (frag.claimed) revert SoftMoltNothingToClaim();

        frag.claimed = true;

        uint256 base = uint256(frag.tier) * 1e15;
        uint256 streak = _playerState[msg.sender].streakBonus;
        uint256 bonus = base + (streak * 2e14);

        emit FragmentClaimed(msg.sender, fragmentId, bonus);
    }

    function getPlayerShells(address player)
        external
        view
        returns (
            uint8[] memory tiers,
            uint256[] memory riftCycles,
            bool[] memory claimed
        )
    {
        ShellFragment[] storage shells = _playerShells[player];
        uint256 len = shells.length;
        tiers = new uint8[](len);
        riftCycles = new uint256[](len);
        claimed = new bool[](len);

        for (uint256 i = 0; i < len; i++) {
            tiers[i] = shells[i].tier;
            riftCycles[i] = shells[i].riftCycle;
            claimed[i] = shells[i].claimed;
        }
