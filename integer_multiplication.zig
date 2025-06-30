const std = @import("std");

const Cost = struct {
    // 0 if cost undefined
    n: u16 = 0,
    value: u16 = 0,
    smaller: ?*const Cost = null,
    larger: ?*const Cost = null,
    negative: bool = false,
    made: std.StaticBitSet(256) = std.StaticBitSet(256).initEmpty(),
};

const NumberCost = struct {
    lowest: Cost,
    by_term: [256]Cost,
};

var costs: [256]NumberCost = undefined;

fn calcTerm(n: u16) void {
    costs[n] = .{
        .lowest = Cost{
            .n = n,
            .value = std.math.maxInt(u16),
            .larger = null,
            .smaller = null,
            .made = undefined,
        },
        .by_term = [1]Cost{.{}} ** 256,
    };
    for (1..n) |i| {
        if (i >= n / 2 + 1) break;
        const larger: u16 = n - @as(u16, @intCast(i));
        const smaller: u16 = @intCast(i);

        var cost = Cost{
            .n = n,
            .value = costs[larger].lowest.value + costs[smaller].lowest.value + 1,
            .larger = &costs[larger].lowest,
            .smaller = &costs[smaller].lowest,
            .made = costs[larger].lowest.made.unionWith(costs[smaller].lowest.made),
        };
        cost.made.set(n);
        insertCost(n, cost);
        if (costs[larger].by_term[smaller].n != 0) {
            var shortcut_cost = Cost{
                .n = n,
                .value = costs[larger].by_term[smaller].value + 1,
                .larger = &costs[larger].by_term[smaller],
                .smaller = null,
                .made = costs[larger].by_term[smaller].made,
            };
            shortcut_cost.made.set(n);
            insertCost(n, shortcut_cost);
        }
    }
}

fn negativePass(n: u16) void {
    for (2..256) |i| {
        const larger: i16 = @as(i16, @intCast(i));
        const smaller: i16 = @as(i16, @intCast(n)) - larger;
        if (smaller > larger) continue;
        if (smaller == 0) continue;

        var cost = Cost{
            .n = n,
            .value = costs[@intCast(larger)].lowest.value + costs[@abs(smaller)].lowest.value + 1,
            .negative = smaller < 0,
            .larger = &costs[@intCast(larger)].lowest,
            .smaller = &costs[@abs(smaller)].lowest,
            .made = costs[@intCast(larger)].lowest.made.unionWith(costs[@abs(smaller)].lowest.made),
        };
        cost.made.set(n);
        insertCost(n, cost);
        if (costs[@intCast(larger)].by_term[@abs(smaller)].n != 0) {
            var shortcut_cost = Cost{
                .n = n,
                .value = costs[@intCast(larger)].by_term[@abs(smaller)].value + 1,
                .larger = &costs[@intCast(larger)].by_term[@abs(smaller)],
                .smaller = null,
                .made = costs[@intCast(larger)].by_term[@abs(smaller)].made,
            };
            shortcut_cost.made.set(n);
            insertCost(n, shortcut_cost);
        }
    }
}

fn insertCost(n: u16, cost: Cost) void {
    if (cost.value < costs[n].lowest.value) {
        costs[n].lowest = cost;
    }
    var iter = cost.made.iterator(.{});
    while (iter.next()) |idx| {
        if (costs[n].by_term[idx].n != 0) {
            if (cost.value < costs[n].by_term[idx].value) {
                costs[n].by_term[idx] = cost;
            }
        } else {
            costs[n].by_term[idx] = cost;
        }
    }
}

fn buildOne() void {
    costs[1] = .{
        .lowest = undefined,
        .by_term = [1]Cost{.{}} ** 256,
    };
    var cost = Cost{
        .n = 1,
        .value = 0,
        .smaller = null,
        .larger = null,
        .made = std.StaticBitSet(256).initEmpty(),
    };
    cost.made.set(1);
    costs[1].lowest = cost;
    costs[1].by_term[1] = cost;
}

fn printPath(cost: *const Cost) !void {
    const out = std.io.getStdOut().writer();
    try out.print("{d}=", .{cost.n});
    if (cost.larger) |larger| {
        try out.print("{d}", .{larger.n});
    } else {
        try out.writeByte('?');
    }
    try out.writeByte(if (cost.negative) '-' else '+');
    if (cost.smaller) |smaller| {
        try out.print("{d}", .{smaller.n});
    } else {
        try out.writeByte('?');
    }
    try out.writeByte('\n');
    if (cost.larger) |larger| {
        try printPath(larger);
    }
}

// 2307
// 2139
// 2105
pub fn main() !void {
    buildOne();
    const out = std.io.getStdOut().writer();
    var sum: u16 = 0;
    for (2..256) |i| {
        calcTerm(@intCast(i));
    }
    for (0..2) |_| {
        sum = 0;
        for (2..256) |i| {
            negativePass(@intCast(i));
            sum += costs[i].lowest.value;
        }
    }
    try out.print("{d}\n", .{sum});
}
