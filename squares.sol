pragma solidity ^0.4.19;

contract squares {
    struct bet {
        address better;
        uint256 value;
        uint8 row;
        uint8 col;
    }
    struct Board {
        uint8[10] numbers_x;
        uint8[10] numbers_y;
        bool[10] yPicked;
        bool[10] xPicked;
        bet[][10][10] bets;
        uint256[10][10] squareTotal;
        uint256 allBets;
    }
    
    address public owner;
    Board public gameBoard;
    bool public numbers_drawn;
    bool public scoreSubmitted;
    bool public gameStarted;
    uint8 public finalScoreX = 0;
    uint8 public finalScoreY = 0;
    mapping (address => bet[]) placedBets;
    
    function NewGame() public {
        if (gameStarted) return;
        owner = msg.sender;
        gameStarted = true;
    }
    
    function SubmitScore(uint8 x, uint8 y) public {
        if (msg.sender != owner && !numbers_drawn) return;
        finalScoreX = x;
        finalScoreY = y;
        uint256 commission = gameBoard.allBets / 100 * 3;
        uint256 finalPayout = gameBoard.allBets - commission;
        uint256 winningSquareTotal = gameBoard.squareTotal[finalScoreX][finalScoreY];
        owner.transfer(commission);
        bet[] memory winningBets = gameBoard.bets[gameBoard.numbers_x[finalScoreX]][gameBoard.numbers_y[finalScoreY]];
        for (uint8 winningBet = 0; winningBet < gameBoard.bets[finalScoreX][finalScoreY].length; winningBet++){
            winningBets[winningBet].better.transfer( winningSquareTotal / winningBets[winningBet].value * finalPayout );
        }
    }
    
    function getSquare(uint8 squareX, uint8 squareY)  public constant returns(uint256 bets, uint256 total) {
        return (gameBoard.bets[squareX][squareY].length, gameBoard.squareTotal[squareX][squareY]);
    }
    
    function getTotalBetAmount() public constant returns( uint256 total) {
        return gameBoard.allBets;
    }
    
    function getAddresBets() public constant returns (uint8[] ,uint8[] , uint256[] ) {
        uint8[] x;
        uint8[] y;
        uint256[] amount;
        for (uint8 betIndex = 0; betIndex < placedBets[msg.sender].length; betIndex++){
            x[betIndex] = placedBets[msg.sender][betIndex].row;
            y[betIndex] = placedBets[msg.sender][betIndex].col;
            amount[betIndex] = placedBets[msg.sender][betIndex].value;
        }
        return (x,y,amount);
    }
    
    event NewBet(uint8 squareX, uint8 squareY, uint256 num_bets, uint256 total_bet);
    
    function PlaceBet(uint8 squareX, uint8 squareY) public payable{
        if (numbers_drawn) return;
        bet memory yourBet = bet(msg.sender,msg.value, squareX, squareY);
        placedBets[msg.sender].push(yourBet);
        gameBoard.bets[squareX][squareY].push(yourBet);
        gameBoard.squareTotal[squareX][squareY] += msg.value;
        gameBoard.allBets += msg.value;
        NewBet(squareX,squareY,gameBoard.bets[squareX][squareY].length,gameBoard.squareTotal[squareX][squareY]);
    }
    
    function DrawNumbers() public {
        if (msg.sender != owner || numbers_drawn) return;
        numbers_drawn = true;
        uint8 blockcount = 1;
        uint8 xnumbercount = 0;
        uint8 ynumbercount = 0;
        uint8 number;
        while (xnumbercount < 10){
            number = uint8(block.blockhash(block.number-(blockcount)))%10;
            if (!gameBoard.xPicked[number]){
                gameBoard.numbers_x[xnumbercount] = number;
                gameBoard.xPicked[number]= true;
                xnumbercount++;
            }
            blockcount++;
            
            if( blockcount > 150)
                xnumbercount = 10;
                numbers_drawn = false;
        }
        while (ynumbercount < 10){
            number = uint8(block.blockhash(block.number-(blockcount)))%10;
            if (!gameBoard.yPicked[number]){
                gameBoard.numbers_y[ynumbercount] = number;
                gameBoard.yPicked[number]= true;
                ynumbercount++;
            } 
            blockcount++;
            if( blockcount > 200){
                ynumbercount = 10;
                numbers_drawn = false;
            }
        }
    }
}
