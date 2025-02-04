const sol = @import("solana-program-sdk");
const caramello = @import("caramello");
// const caramello = @import("../../../src/root.zig");

const ReadonlyAccount = caramello.ReadonlyAccount;
const WritableAccount = caramello.WritableAccount;

export fn entrypoint(input: [*]u8) u64 {
    _ = sol.Context.load(input) catch return 1;
    const context = sol.Context.load(input) catch return 1;
    const accounts = context.accounts;

    // var counter_account = WritableAccount(Counter, true).from(&accounts[0]);
    // const owner_account = WritableAccount(Counter, true).from(&accounts[1]);
    // const counter_two_account = ReadonlyAccount(Counter, true).from(&accounts[2]);

    var counter_account = caramello.Writable(Counter).from(@constCast(&accounts[0]));
    const owner_account = caramello.Writable(Counter).from(@constCast(&accounts[1]));
    const counter_two_account = caramello.Writable(Counter).from(@constCast(&accounts[2]));

    const counter_data = counter_account.data();

    sol.log("Hello try to make readable account");

    counter_account.__account.data()[32] = 5;
    counter_data.count += 1;

    counter_data.owner = owner_account.id();

    sol.print("counter count: {d}", .{counter_data.count});
    sol.print("counter owner : {s}", .{counter_data.owner});
    sol.print("counter program : {s}", .{counter_account.owner_id()});
    sol.print("counter two program : {s}", .{counter_two_account.owner_id()});
    sol.print("counter two data: {any}", .{counter_account.__account.data()[32..]});

    const counter_lamports = counter_account.lamports();
    const counter_two_lamports = counter_two_account.lamports();

    const amount = 3_000_000;

    sol.print("counter lamports: {d}", .{counter_account.lamports().*});
    sol.print("counter two lamports : {d}", .{counter_two_account.lamports().*});

    counter_lamports.* -= amount;
    counter_two_lamports.* += amount;

    sol.print("counter lamports: {d}", .{counter_account.lamports().*});
    sol.print("counter two lamports : {d}", .{counter_two_account.lamports().*});

    return 0;
}

const IncrementContext = extern struct {
    counter: WritableAccount(Counter, false),
    owner: ReadonlyAccount(Counter, true),
    counter_two: ReadonlyAccount(Counter, true),

    pub const @"*init" = .{"counter"};
    pub const @"*init_if_needed" = .{"counter_two"};

    pub const @"*counter:seeds" = .{ "*owner", "*.count", "*.payer" };
    pub const @"*counter:bump" = "*";

    pub const @"*counter_two:seeds" = .{ "*owner", "*.count", "*.payer" };
};

const Counter = packed struct {
    owner: sol.PublicKey,
    count: u64,
};

