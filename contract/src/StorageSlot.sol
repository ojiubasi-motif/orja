// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract StorageSlot {
    uint256 number;

    uint128 public a;
    uint64 public b;
    uint32 public c;
    uint32 public d;

    uint128[] dyn1 = [1, 2, 3, 4, 5, 6, 7];
    uint32[] dyn2;
    uint64[] dyn3;

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

    function getHashOfdyn1()
        public
        view
        returns (bytes32, uint _dynlen, uint _slot)
    {
        // uint slot;
        assembly {
            _slot := dyn1.slot
            _dynlen := sload(_slot)
        }
        return (keccak256(abi.encode(_slot)), _dynlen, _slot);
    }

    function sloadArrayData1(
        uint256 _indexOfItem
    ) public view returns (uint128 val, bytes32 b32, uint len, uint _itemSlot) {
        require(_indexOfItem < dyn1.length);
        (bytes32 dynHash, uint _dynlen, ) = getHashOfdyn1();

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
        //    return  dynHash + slot;
    }

    function sloadMapping() public view returns (uint256[] memory) {}
}
