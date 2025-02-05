const std = @import("std");
const solana = @import("solana-program-sdk");
const spl = @import("solana-program-library");
const root = @import("root.zig");

const WritableAccount = root.WritableAccount;
const ReadonlyAccount = root.ReadonlyAccount;

pub fn Context(comptime T: type) [3]u8 {
    const fields = @typeInfo(T).Struct.fields; // Get all fields
    // const decls = @typeInfo(T).Struct.decls; // Get all declarations

    const props: [3][]const u8 = .{ "seeds", "bump", "init" };

    var props_count: [3]u8 = .{ 0, 0, 0 };

    // Iterate over each field
    inline for (fields) |field| {
        const prefix = "*" ++ field.name ++ ":";

        inline for (props, 0..) |prop, i| {
            const check = prefix ++ prop;

            if (@hasDecl(T, check)) {
                props_count[i] += 1;
            }
        }
    }

    return props_count;
}

pub fn getCheckCount(comptime T: type, comptime check: []const u8) comptime_int {
    comptime {
        const fields = @typeInfo(T).Struct.fields; // Get all fields
        // const decls = @typeInfo(T).Struct.decls; // Get all declarations

        var count = 0;

        // Iterate over each field
        for (fields) |field| {
            const prefix = "*" ++ field.name ++ ":";

            const _check = prefix ++ check;

            if (@hasDecl(T, _check)) {
                count += 1;
            }
        }

        return count;
    }
}

pub fn getAccountsForCheck(comptime context: type, comptime len: comptime_int, comptime check: []const u8) [len][]const u8 {
    comptime {
        const fields = @typeInfo(context).Struct.fields; // Get all fields
        // const decls = @typeInfo(T).Struct.decls; // Get all declarations
        var value: [len][]const u8 = undefined;

        var count = 0;

        // Iterate over each field
        for (fields) |field| {
            const prefix = "*" ++ field.name ++ ":";
            const _check = prefix ++ check;

            if (@hasDecl(context, _check)) {
                value[count] = field.name;
                count += 1;
            }
        }

        return value;
    }
}

const InitContext = struct {
    // the index of the account
    account: u8,
    //  the index of the payer
    payer: u8,
    // is it a pda account
    seeds: bool,
};

pub fn getInit(comptime context: type, comptime account: []const u8) ?InitContext {
    comptime {
        const init_count = getCheckCount(context, "seeds");
        const val = getAccountsForCheck(context, init_count, "init");

        var found = false;

        for (val) |v| {
            if (std.mem.eql(u8, v, account)) {
                found = true;
                break;
            }
        }

        if (!found) {
            return null;
        }

        const parsed = "*" ++ account ++ ":" ++ "init";

        const do: []const u8 = @field(context, parsed);

        const payer_index = getAccountIndex(context, do);

        const seeds_check = getCheckCount(context, "seeds");
        const seeds = getAccountsForCheck(context, seeds_check, "seeds");

        var is_seeds = false;

        const account_index = getAccountIndex(context, account);

        for (seeds) |v| {
            if (std.mem.eql(u8, v, account)) {
                is_seeds = true;
                break;
            }
        }

        return InitContext{
            .account = account_index,
            .payer = payer_index,
            .seeds = is_seeds,
        };
    }
}

pub fn getAccountIndex(comptime context: type, comptime account: []const u8) u8 {
    comptime {
        const fields = @typeInfo(context).Struct.fields; // Get all fields

        for (fields, 0..) |field, i| {
            if (std.mem.eql(u8, field.name, account)) {
                return i;
            }
        }

        return 255;
    }
}

pub fn syncAccounts(comptime ContextType: type, accounts: []solana.Account) ContextType {
    const fields = @typeInfo(ContextType).Struct.fields;
    // if (fields.len != accounts.len) {
    //     @compileError("Mismatch between struct fields and provided accounts.");
    // }

    // Create an instance of ContextType
    var context: ContextType = undefined;

    inline for (fields, 0..) |field, i| {
        // Ensure the field type matches *solana.Account
        // if (@typeInfo(field.type) != @typeInfo(*solana.Account)) {
        //     @compileError("Field '" ++ field.name ++ "' must be of type '*solana.Account'.");
        // }

        // Assign field programmatically
        @field(context, field.name) = field.type.from(&accounts[i]);
    }

    return context;
}

test "so" {
    const Counter = packed struct {
        count: u64,
    };

    const IncrementContext = extern struct {
        counter: Counter,
        owner: Counter,
        counter_two: Counter,

        const @"*counter:init" = "owner";
        const @"*counter:space" = 40;
        const @"*counter:seeds" = .{ "*owner", "*.count", "*.payer" };
        const @"*counter:bump" = "*";

        const @"*counter_two:init_if_needed": []const u8 = "owner";
        const @"*counter_two:seeds": [3][]const u8 = .{ "*owner", "*.count", "*.payer" };
    };

    const so, const yo, const do = comptime Context(IncrementContext);

    const init_check = comptime getCheckCount(IncrementContext, "init");
    const seeds_check = comptime getCheckCount(IncrementContext, "seeds");

    // var init_accounts = [init_check][]const u8{"" ** init_check};

    const val = comptime getAccountsForCheck(IncrementContext, seeds_check, "seeds");
    const init_val = comptime getAccountsForCheck(IncrementContext, init_check, "init");

    const counter_index = comptime getAccountIndex(IncrementContext, "counter");
    const owner_index = comptime getAccountIndex(IncrementContext, "owner");

    const init_ctx = comptime getInit(IncrementContext, "counter");

    std.debug.print("\n", .{});
    std.debug.print("so: {d}\n", .{so});
    std.debug.print("yo: {d}\n", .{yo});
    std.debug.print("do: {d}\n", .{do});
    std.debug.print("init count: {d}\n", .{init_check});
    std.debug.print("seeds count: {d}\n", .{seeds_check});
    std.debug.print("val: {s}\n", .{val});
    std.debug.print("init val: {s}\n", .{init_val});
    std.debug.print("counter index: {d}\n", .{counter_index});
    std.debug.print("owner index: {d}\n", .{owner_index});
    std.debug.print("init ctx: {?}\n", .{init_ctx});
    std.debug.print("\n", .{});
}
