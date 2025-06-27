// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
    uint256 number;
    //slot-0
    uint128 public a;
    uint64 public b;
    uint32 public c;
    uint32 public d;
    // slot-1
    uint128[] dyn1 = [1, 2, 3, 4, 5, 6, 7];
    uint32[] dyn2;
    uint64[] dyn3;
    // slot-2
    mapping(uint8 => uint64[]) public map1;

    constructor() {
        map1[2] = [1, 3, 22, 33, 11, 4, 5, 6];
        map1[1] = [2, 4, 5, 6, 7];
    }

    string[] testArr = new string[](10);

    function sstore() public {
        assembly {
            let v := sload(1)

            let mask_a := not(sub(shl(128, 1), 1))
            v := and(v, mask_a)
            v := or(v, 11)

            let mask_b := not(shl(128, sub(shl(64, 1), 1)))
            v := and(v, mask_b)
            v := or(v, shl(128, 22))

            let mask_c := not(shl(192, sub(shl(32, 1), 1)))
            v := and(v, mask_c)
            v := or(v, shl(192, 33))

            let mask_d := not(shl(224, sub(shl(32, 1), 1)))
            v := and(v, mask_d)
            v := or(v, shl(224, 44))

            sstore(1, v)
            // sstore(1,v)
        }
    }

    function getArray(uint8 key) external view returns (uint64[] memory) {
        return map1[key]; // ✅ allowed inside internal/external function, but not via public mapping getter
    }

    function getMap1Slot(uint8 key)
        public
        pure
        returns (bytes32 hash, uint256 _slotNum)
    {
        uint256 mapSlot;
        assembly {
            mapSlot := map1.slot
            _slotNum := mapSlot
        }
        hash = keccak256(abi.encode(key, uint256(mapSlot)));
    }

    function sloadMap1(uint8 _key, uint _indexOfItem)
        public
        view
        returns (uint64 _arrItem, uint64 arrlen)
    {
        (bytes32 hash, uint _slotNum ) = getMap1Slot(_key);
        bytes32 baseHash = keccak256(abi.encode(hash));//hash again the hash returned from the mapping hash
        assembly {
           let slot
            let maxDataPerSlot := div(256, 64)
            if iszero(_indexOfItem) {
                slot := 0
            }
            if gt(_indexOfItem, 0) {
                slot := div(_indexOfItem, maxDataPerSlot)
            }
            let loadedSlotVal := sload(add(baseHash, slot))
            _arrItem := shr(
                mul(mod(_indexOfItem, maxDataPerSlot), 64),
                loadedSlotVal
            )
            arrlen := sload(hash)
        
        }
    }

    function getHashOfdyn1()
        public
        view
        returns (
            bytes32,
            uint256 _dynlen,
            uint256 _slot
        )
    {
        // uint slot;
        assembly {
            _slot := dyn1.slot
            _dynlen := sload(_slot)
        }
        return (keccak256(abi.encode(_slot)), _dynlen, _slot);
    }

    function sloadArrayData1(uint256 _indexOfItem)
        public
        view
        returns (
            uint128 val,
            bytes32 b32,
            uint256 len,
            uint256 _itemSlot
        )
    {
        require(_indexOfItem < dyn1.length);
        (bytes32 dynHash, uint256 _dynlen, ) = getHashOfdyn1();

        assembly {
            let slot
            let maxDataPerSlot := div(256, 128)
            if iszero(_indexOfItem) {
                slot := 0
            }
            if gt(_indexOfItem, 0) {
                slot := div(_indexOfItem, maxDataPerSlot)
            }
            let loadedSlotVal := sload(add(dynHash, slot))
            val := shr(
                mul(mod(_indexOfItem, maxDataPerSlot), 128),
                loadedSlotVal
            )
            b32 := val
            _itemSlot := slot
            len := _dynlen
        }
    }

    // function sloadMapping() public view returns(uint256[] memory){

    // }
}
