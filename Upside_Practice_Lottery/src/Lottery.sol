// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery {
    
    address public owner;
    mapping (address => uint256) public tickets;
    uint256 public received_msg_value;
    uint16 public winningNumber;
    uint256 public start_time; 
    constructor() {
        owner = msg.sender;
        start_time = block.timestamp;
    }

    function buy(uint256 _number) public payable {
        require(msg.value == 0.1 ether, "you must send 0.1 ether");
        require(tickets[msg.sender] == 0, "you already have a ticket");
        require(block.timestamp < start_time + 24 hours, "sell is over~~");

        tickets[msg.sender] = _number +1; //구매하지 않은 상태와 0을 구분하려고 1더함
        
    }

    function draw() public {
        require(msg.sender == owner, "only owner can draw");
        require(block.timestamp >= start_time + 24 hours, "waiting for sell phase end zz"); //판매 기간엔 뽑기 안됨
        
        winningNumber = uint16(block.prevrandao % 65536); //당첨번호 설정
    }

    function claim() public {
        require(tickets[msg.sender] == 1, "you didn't win");
        require(block.timestamp > start_time + 24 hours, "waiting for sell end zz");
        
    }

    function getWinningNumber() public view returns (uint16){  
        return winningNumber;

    }
}