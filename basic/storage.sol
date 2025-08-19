// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {

    uint storedData;
    
    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}

// storage:
    // 1.  永久存在鏈上
    // 2.  屬於合約的狀態變數
    // 3.  修改會花費Gas

// memory:
    // 1.  暫時存在函數執行過程(EVM記憶體)
    // 2.  呼叫結束會消失(不會寫入鏈上)
    // 3.  讀寫比較便宜，不會消耗永久儲存的Gas
    // 4.  用於函數的參數，臨時變數

// calldata:
    // 1.  也是暫時的，只能讀取
    // 2.  從交易或函數呼叫傳進來的參數
    // 3.  比memory更省Gas