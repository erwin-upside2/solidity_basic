// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery {
   address public owner;  // 컨트랙트 배포자 저장
   mapping (address => uint256) public tickets;  // 참가자 주소 기반으로 구매한 티켓의 정보(번호)를 저장
   uint16 public winningNumber;  // 당첨번호
   uint256 public start_time;  // 라운드 시작된 시점의 블록 타임스탬프
   uint256 public jackpot;  // 당첨자 없을 때 이월되는 상금 (롤오버)
   bool public round_over;  // 라운드 종료 여부; 라운드 끝나면 새로운 로또 판매
   bool public draw_over;  // 당첨자 추첨 여부; 추첨 끝나야 claim 가능
   uint256 public winnerCount;  // 당첨자 수 저장
   uint256 public prizePool;  // 현재 라운드의 상금 풀

   constructor() {
       owner = msg.sender;  // 컨트랙트 배포한 사람이 로또 주인
       start_time = block.timestamp;  // 배포 시점을 라운드 시작 시간으로 설정
       draw_over = false;  // 아직 당첨자가 결정되지 않음
       round_over = false;  // 아직 라운드가 진행 중
       jackpot = 0;  // 이월되는 상금 초기화
       prizePool = 0;  // 상금 풀 초기화
   }

   function buy(uint256 _number) public payable {
       require(msg.value == 0.1 ether, "you must send 0.1 ether");  // 0.1eth가 아니면 실패
       require(tickets[msg.sender] == 0, "you already have a ticket");  // 중복 구매 방지
       require(block.timestamp < start_time + 24 hours, "sell is over~~");  // 24시간 이후에 구매 불가
        //tickets[msg.seder]는 tx실행한 사용자가 선택한 로또의 번호를 반환
       tickets[msg.sender] = _number + 1;  // 구매하지 않은 상태와 0을 구분하려고 1더함
       prizePool += 0.1 ether;  // 구매금액을 상금 풀에 추가
   }   

   function draw() public {
       require(msg.sender == owner, "only owner can draw");  // 오너만 추첨 가능
       require(block.timestamp >= start_time + 24 hours, "waiting for sell phase end zz");  // 판매 기간 끝나야 추첨 가능
       require(winningNumber == 0, "winning number already set");  // 이미 당첨번호가 설정되어 있으면 안됨
       require(round_over == false, "round is over");  // 라운드 끝나면 실행 불가
       require(draw_over == false, "draw is over");  // 이미 추첨 완료됐으면 실행 불가

       winningNumber = uint16(block.prevrandao % 65536);  // 당첨번호 설정
       
       // 당첨자 수 계산
       winnerCount = 0;
       if (tickets[msg.sender] != 0 && tickets[msg.sender] - 1 == winningNumber) winnerCount++;
       if (tickets[address(1)] != 0 && tickets[address(1)] - 1 == winningNumber) winnerCount++;
       
       draw_over = true;  // 추첨 완료
   }

   function claim() public {
    require(block.timestamp >= start_time + 24 hours, "waiting for sell end zz");
    require(draw_over, "draw is not over yet");

    if (tickets[msg.sender] - 1 == winningNumber) {  // 상금 분배
        uint256 payout;
        if (winnerCount > 1) {
            payout = 0.1 ether;
        } else {
            payout = prizePool + jackpot;
        }
            
        tickets[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: payout}("");  // call 함수는 (bool, bytes) 반환값 가짐. 여기선 bytes 생략하려고 ', ' 사용
        require(success, "Transfer failed.");

        // 마지막 당첨자가 claim했을 때만 새 라운드 시작
        if (address(this).balance == 0) {
            start_time = block.timestamp;
            winningNumber = 0;
            draw_over = false;
            round_over = false;
            winnerCount = 0;
            prizePool = 0;
        }
    } else {
        jackpot += 0.1 ether;
        tickets[msg.sender] = 0;

        // 미당첨자의 경우에만 새 라운드 시작
        start_time = block.timestamp;
        winningNumber = 0;
        draw_over = false;
        round_over = false;
        winnerCount = 0;
        prizePool = 0;
    }
}

   function getWinningNumber() public view returns (uint16) {
       return winningNumber;
   }
}