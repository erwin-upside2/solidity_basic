// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz{

    address public owner; //컨트랙트 소유자
    mapping(uint => Quiz_item) public quizzes; //퀴즈 저장소
    uint public quiz_num; //퀴즈 개수

    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
   }
    
    mapping(address => uint256)[] public bets;
    uint public vault_balance;

    receive() external payable {
        vault_balance += msg.value; // 받은 이더를 vault_balance에 추가
    }

    constructor () {
        owner = msg.sender; //배포자를 owner로 설정
        quiz_num = 0;
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function addQuiz(Quiz_item memory q) public {
        require(msg.sender == owner, "only owner can add quiz"); // (접근 제어)owner만 호출 가능
        require(q.id == quiz_num + 1, "quiz id must increase sequentially"); // 퀴즈 ID 유효성 검증

        quizzes[q.id] = q;
        quiz_num += 1;

    }

    function getAnswer(uint quizId) public view returns (string memory){
        require(quizId > 0 && quizId <= quiz_num, "quiz doesn't exist"); // 퀴즈 ID 유효성 검증

        return quizzes[quizId].answer; //해당 퀴즈의 정답 반환

    }

    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        require(quizId > 0 && quizId <= quiz_num, "invalid quiz id"); // 퀴즈 ID 유효성 검증

        Quiz_item memory quiz = quizzes[quizId]; // 퀴즈 정보 가져오기

        quiz.answer = "";  // 답안 hiding

        return quiz;

    }

    function getQuizNum() public view returns (uint){
        return quiz_num;
    }
    
    function betToPlay(uint quizId) public payable {
        // 퀴즈 존재 여부 확인
        require(quizId > 0 && quizId <= quiz_num, "quiz doesn't exist"); // 퀴즈 존재 여부 확인
        // 퀴즈 정보 가져오기
        Quiz_item memory quiz = quizzes[quizId];

        // 베팅 ㅇ금액 검증
        require(msg.value >= quiz.min_bet, "Bet amount too low");
        require(msg.value <= quiz.max_bet, "Bet amount too high");

        // 베팅 정보 저장
        while (bets.length < quizId) {
            bets.push();
        }

        // 베팅 금액 추가
        bets[quizId -1][msg.sender] += msg.value;
        
        // 잔액 업데이트
        vault_balance += msg.value;
        
    }

    function solveQuiz(uint quizId, string memory ans) public returns (bool) {

        require(quizId > 0 && quizId <= quiz_num, "quiz doesn't exist"); // 퀴즈 존재 여부 확인

        require(bets[quizId - 1][msg.sender] > 0, "no bet found"); // 베팅 금액 확인

        uint256 current_bet = bets[quizId - 1][msg.sender]; //현재 베팅 금액 저장

        bets[quizId - 1][msg.sender] = 0; //베팅초기화

        bool correct = keccak256(abi.encodePacked(ans)) == keccak256(abi.encodePacked(quizzes[quizId].answer)); //정답 확인

        if (!correct) {
            vault_balance += current_bet;
            return false;
        }
        //정답인 경우 claim을 위한 표시
        bets[0][msg.sender] = current_bet;
        return true;

    }

    function claim() public {
        uint256 original_bet = bets[0][msg.sender];
        require(bets[0][msg.sender] > 0 , "not eligible for claim"); //정답 맞춘 사람인지 확인

        uint256 reward = original_bet * 2; 
        require(vault_balance >= reward, "Insufficient vault balance");


        bets[0][msg.sender] = 0; // 기록 초기화
        vault_balance -= reward;  //vault 잔액 감소

        (bool sent, ) = payable(msg.sender).call{value: reward}(""); //상금 지급
        require(sent, "failed to send reward");


    }

}
