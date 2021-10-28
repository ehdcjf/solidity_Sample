pragma solidity ^0.8.4;
contract Purchase {
  uint public value;
  address payable public seller;
  address payable public buyer;

  enum State{Created, Locked,Release, Inactive}
  //상태변수는 첫번째멤버를  기본값으로 가지고 있음
  // State.Created
  State public state;

  modifier condition(bool condition_){
    require(condition_);
    _;
  }

  // 구매자, 판매자만 함수를 호출할 수 있다. 
  error OnlyBuyer();
  error OnlySeller();

  // 현재 상태에서 호출될 수 없다??,,
  error InvalidState();

  // 짝수만?....
  error ValueNotEven();

  modifier onlyBuyer(){
    if(msg.sender != buyer)
      revert OnlyBuyer();
    _;
  }

  modifier onlySeller(){
    if(msg.sender != seller)
      revert OnlySeller();
    _; 
  }

  modifier inState(State state_){
    if(state != state_)
      revert InvalidState();
    _;
  }

  event Aborted();
  event PurchaseConfirmed();
  event ItemReceived();
  event SellerRefunded();

  // msg.value는 짝수여야함!
  constructor() payable {
    seller = payable(msg.sender);
    value = msg.value /2;
    if((2*value) != msg.value)
      revert ValueNotEven();
  }


  function abort()
    external
    onlySeller
    inState(State.Created)
  {
    emit Aborted();
    state = State.Inactive;
    // 직접 전송함. 재진입이 안전하니까. 왜냐면 이게 이 함수의
    // 마지막 호출이고, 이미 상태를 바꿨으니까 
    seller.transfer(address(this).balance);
  }
  

  // 구매자가 구매를 확인
  // 트랜잭션에는 2*value 이더가 포함되어야함.
  // 이더는 확인 수신이 호출될 때 까지 잠겨있음.
      /// Confirm the purchase as buyer.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function confirmPurchase()
        external
        inState(State.Created)
        condition(msg.value == (2 * value))
        payable
    {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    /// Confirm that you (the buyer) received the item.
    /// This will release the locked ether.
    function confirmReceived()
        external
        onlyBuyer
        inState(State.Locked)
    {
        emit ItemReceived();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Release;

        buyer.transfer(value);
    }

    /// This function refunds the seller, i.e.
    /// pays back the locked funds of the seller.
    function refundSeller()
        external
        onlySeller
        inState(State.Release)
    {
        emit SellerRefunded();
        // It is important to change the state first because
        // otherwise, the contracts called using `send` below
        // can call in again here.
        state = State.Inactive;

        seller.transfer(3 * value);
    }

  
  

}