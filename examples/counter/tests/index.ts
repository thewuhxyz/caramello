import {
	Keypair,
	LAMPORTS_PER_SOL,
	PublicKey,
	SystemProgram,
	Transaction,
	TransactionInstruction,
} from "@solana/web3.js";
import { start } from "solana-bankrun";

async function main() {
	const PROGRAM_ID = new PublicKey("11111111111111111111111111111112");
	const context = await start(
		[{ name: "counter", programId: PROGRAM_ID }],
		[]
	);
	const client = context.banksClient;
	const payer = context.payer;

	const newCounter = Keypair.generate();
	const wrongCounter = Keypair.generate();

	const rent = await client.getRent()
	const space = 40
	const lamports = Number(rent.minimumBalance(BigInt(space)))

	const create_ix = SystemProgram.createAccount({
		fromPubkey: payer.publicKey,
		lamports,
		newAccountPubkey: newCounter.publicKey,
		programId: PROGRAM_ID,
		space,
	});
	
	const create_ix_2 = SystemProgram.createAccount({
		fromPubkey: payer.publicKey,
		lamports,
		newAccountPubkey: wrongCounter.publicKey,
		programId: PROGRAM_ID,
		space,
	});

	const transfer = SystemProgram.transfer({
		fromPubkey: payer.publicKey,
		toPubkey: newCounter.publicKey,
		lamports: 0.1 * LAMPORTS_PER_SOL
	})

	const assign_ix = SystemProgram.assign({
		accountPubkey: newCounter.publicKey,
		programId: PROGRAM_ID,
	});
	
	const assign_ix_2 = SystemProgram.assign({
		accountPubkey: wrongCounter.publicKey,
		programId: PROGRAM_ID,
	});

	const increment_ix = new TransactionInstruction({
		keys: [
			{
				pubkey: newCounter.publicKey,
				isSigner: false,
				isWritable: false,
			},
			{
				pubkey: payer.publicKey,
				isSigner: false,
				isWritable: false,
			},
			{
				pubkey: wrongCounter.publicKey,
				isSigner: false,
				isWritable: true,
			},
		],
		programId: PROGRAM_ID,
	});

	const transaction = new Transaction();

	transaction.instructions = [create_ix, create_ix_2, assign_ix, transfer, assign_ix_2, increment_ix];
	transaction.feePayer = payer.publicKey;
	transaction.recentBlockhash = context.lastBlockhash;
	transaction.sign(payer, newCounter, wrongCounter);

	const _ = await client.processTransaction(transaction);

	const account = await client.getAccount(newCounter.publicKey);
	let accountData = account?.data!;

	let maybeOwner = Uint8Array.from(accountData).slice(0, 32);
	let maybeOwnerPk = new PublicKey(maybeOwner);
	console.log("owner:", maybeOwnerPk.toBase58());
	
	let maybeCount = Uint8Array.from(accountData).slice(32);
	let countBuf = Buffer.from(maybeCount);
	let count = countBuf.readBigUInt64LE();
	console.log("maybe count:", count.toString());

	let counter_lamports = await client.getBalance(newCounter.publicKey)
	let counter_two_lamports = await client.getBalance(wrongCounter.publicKey)

	console.log("balance:", counter_lamports)
	console.log("balance two:", counter_two_lamports)
}

main().catch((e) => console.log(e));
