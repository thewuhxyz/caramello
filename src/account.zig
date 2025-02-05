const solana = @import("solana-program-sdk");

pub fn Readonly(comptime T: type) type {
    return extern struct {
        __account: *const solana.Account,

        const Self = @This();

        pub fn from(account: *const solana.Account) Self {
            return Self{ .__account = account };
        }

        pub fn data(self: Self) *align(1) const T {
            return @ptrCast(@alignCast(self.__account.data()));
        }

        pub fn lamports(self: Self) *const u64 {
            return @ptrCast(self.__account.lamports());
        }

        pub fn id(self: Self) solana.PublicKey {
            return self.__account.id();
        }

        pub fn owner_id(self: Self) solana.PublicKey {
            return self.__account.id();
        }
    };
}

pub fn Writable(comptime T: type) type {
    return extern struct {
        __account: *const solana.Account,

        const Self = @This();

        // usingnamespace Readonly(Self);

        pub fn id(self: Self) solana.PublicKey {
            return self.__account.id();
        }

        pub fn owner_id(self: Self) solana.PublicKey {
            return self.__account.ownerId();
        }

        pub fn from(account: *const solana.Account) Self {
            return Self{ .__account = account };
        }

        pub fn data(self: Self) *align(1) T {
            return @ptrCast(@alignCast(self.__account.data()));
        }

        pub fn lamports(self: Self) *u64 {
            return @ptrCast(self.__account.lamports());
        }
    };
}

pub fn ReadonlyAccount(comptime T: type, comptime signer: bool) type {
    return struct {
        account: *const solana.Account,

        const Self = @This();

        pub fn from(account: *const solana.Account) Self {
            if (signer and !account.isSigner()) {
                solana.log("account is not a signer");
            }
            return Self{ .account = account };
        }

        pub fn data(self: Self) *align(1) const T {
            return @ptrCast(@alignCast(self.account.data()));
        }

        pub fn lamports(self: Self) *const u64 {
            return @ptrCast(self.account.lamports());
        }

        pub fn id(self: Self) solana.PublicKey {
            return self.account.id();
        }

        pub fn owner_id(self: Self) solana.PublicKey {
            return self.account.ownerId();
        }
    };
}

pub fn WritableAccount(comptime T: type, comptime signer: bool) type {
    return struct {
        account: *const solana.Account,

        const Self = @This();

        pub fn from(account: *const solana.Account) Self {
            if (signer and !account.isSigner()) {
                solana.log("account is not a signer");
            }
            return Self{ .account = account };
            // return Self{ .account = @constCast(account) };
        }

        pub fn data(self: Self) *align(1) T {
            return @ptrCast(@alignCast(self.account.data()));
        }

        pub fn lamports(self: Self) *u64 {
            return @ptrCast(self.account.lamports());
        }

        pub fn id(self: *Self) solana.PublicKey {
            return self.account.id();
        }

        pub fn owner_id(self: *Self) solana.PublicKey {
            return self.account.id();
        }

        fn base_account(self: *Self) BaseAccount {
            return .{
                .ptr = self,
                .id_fn = self.id(),
                .owner_id = self.owner_id(),
            };
        }
    };
}

pub const BaseAccount = struct {
    ptr: *anyopaque,

    id_fn: *const fn (ptr: *anyopaque) solana.PublicKey,
    owner_id_fn: *const fn (ptr: *anyopaque) solana.PublicKey,

    fn id(self: BaseAccount) solana.PublicKey {
        return self.id_fn(self.ptr);
    }

    fn owner_id(self: BaseAccount) solana.PublicKey {
        return self.owner_id_fn(self.ptr);
    }
};
