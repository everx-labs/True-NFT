pragma ton-solidity >=0.35.0;

interface INumberInput {

	function get(uint32 answerId, string prompt, int256 min, int256 max) external returns (int256 value);

}

library NumberInput {

	uint256 constant ID = 0xc5a9558b2664aed7dc3e6123436d544f13ffe69ab0e259412f48c6d1c8588401;
	int8 constant DEBOT_WC = -31;

	function get(uint32 answerId, string prompt, int256 min, int256 max) public pure {
		address addr = address.makeAddrStd(DEBOT_WC, ID);
		INumberInput(addr).get(answerId, prompt, min, max);
	}
}

contract NumberInputABI is INumberInput {

	function get(uint32 answerId, string prompt, int256 min, int256 max) external override returns (int256 value) {}

}
