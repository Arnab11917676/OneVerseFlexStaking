pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract SampleToken is ERC20{

    constructor () ERC20('Sample Token','ST'){}
    function _mintToken (uint amount) external {
        _mint(msg.sender, amount);
    }
}
