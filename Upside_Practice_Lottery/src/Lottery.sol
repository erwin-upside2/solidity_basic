// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery {
    
    address public owner;  //컨트랙트 배포자 저장
    mapping (address => uint256) public tickets;  //참가자 주소 기반으로 구매한 티켓의 정보를 저장

    uint16 public winningNumber;   //당첨번호
    uint256 public start_time;   // 라운드 시작된 시점의 블록 타임스탬프
    uint256 public jackpot;         // 당첨자 없을 때 이월되는 상금 (롤오버)
    bool public round_over;            // 라운드 종료 여부; 라운드 끝나면 새로운 로또 판매
    bool public draw_over;                 // 당첨자 추첨 여부; 추첨 끝나야 claim 가능

    constructor() {

        owner = msg.sender;            // 컨트랙트 배포한 사람이 로또 주인
        start_time = block.timestamp;     // 배포 시점을 라운드 시작 시간으로 설정
        draw_over = false;            // 아직 당첨자가 결정되지 않음
        round_over = false;          // 아직 라운드가 진행 중
        jackpot = 0;                // 이월되는 상금 초기화
    }

    function buy(uint256 _number) public payable {
        require(msg.value == 0.1 ether, "you must send 0.1 ether");   //0.1eth가 아니면 실패
        require(tickets[msg.sender] == 0, "you already have a ticket");   // 중복 구매 방지
        require(block.timestamp < start_time + 24 hours, "sell is over~~");  //24시간 이후에 구매 불가

        tickets[msg.sender] = _number +1; 
        // 사용자의 로또 번호를 tickets에 저장. 구매하지 않은 상태와 0을 구분하려고 1더함. 0은 미구매상태임
        
    }

    function draw() public {
        require(msg.sender == owner, "only owner can draw");
        require(block.timestamp >= start_time + 24 hours, "waiting for sell phase end zz"); //판매 끝나야 실행 가능 >=으로 초과한 경우에 뽑도록 함
        require(winningNumber == 0, "winning number already set"); //이미 당첨번호가 설정되어 있으면 뽑기 안됨
        require(round_over == false, "round is over");  // 라운드 끝나면 실행 불가
        require(draw_over == false, "draw is over");        // 이미 추첨 완료됐으면 실행 불가

        winningNumber = uint16(block.prevrandao % 65536); //당첨번호 설정
        
        draw_over = true;   //추첨 완료
    }

function claim() public {
    require(block.timestamp >= start_time + 24 hours, "waiting for sell end zz"); //판매 끝나야 청구가능
    require(draw_over, "draw is not over yet");   // 추첨끝나야 청구 가능

    if (tickets[msg.sender] - 1 == winningNumber) {  
        uint256 balance = address(this).balance;  // 현재 컨트랙트 잔액 저장
        uint256 payout = balance + jackpot;  // `jackpot`을 포함한 총 상금 계산

        if (payout > balance) {
            payout = balance;  // 컨트랙트 잔액을 초과하지 않도록 보정
        }

        jackpot = 0;  // 당첨자 있으면 잭팟 초기화
        tickets[msg.sender] = 0;   //사용자 티켓 정보 초기화 (중복 청구 방지)

        (bool success, ) = msg.sender.call{value: payout}("");  // 당첨자한테 상금 전송
        require(success, "Transfer failed.");
    } else {
        jackpot += 0.1 ether;  // 패배자의 0.1 ETH를 `jackpot`에 추가
        tickets[msg.sender] = 0;  // 패배자의 티켓 제거 (중복 claim 방지)
    }
    // 라운드 초기화
    round_over = false;  
    start_time = block.timestamp;  
    draw_over = false;  
    winningNumber = 0;  
}
    // 당첨 번호 조회 함수, 현재 라운드 당첨번호 반환
    function getWinningNumber() public view returns (uint16){   
        return winningNumber;
    }
}
