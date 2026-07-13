// Regression coverage for the Electric-Imp stubs and the bundled JSON parser.

@include once "src/electric-imp-stubs/agent.stub.nut"
@include once "src/electric-imp-stubs/device.stub.nut"
@include once "src/nutkin.nut"

describe("Electric Imp stub fixes", function() {

    describe("http (agent.stub)", function() {

        it("jsondecode round-trips a jsonencode", function() {
            local api = http();
            local encoded = api.jsonencode({ a = 1, b = "two", c = [3, 4] });
            local decoded = api.jsondecode(encoded);

            expect(decoded.a).to.equal(1);
            expect(decoded.b).to.equal("two");
            expect(decoded.c[0]).to.equal(3);
            expect(decoded.c[1]).to.equal(4);
        });

        it("post records headers and body in captureHistory (not swapped)", function() {
            local api = http();
            api.post("https://example.com", { "Content-Type": "application/json" }, "payload-body");

            local entry = api.captureHistory.top();
            expect(entry.postUrl).to.equal("https://example.com");
            expect(entry.postHeaders["Content-Type"]).to.equal("application/json");
            expect(entry.postBody).to.equal("payload-body");
        });
    });

    describe("crypto (common.stub)", function() {

        it("sha256 hashes the data passed to it", function() {
            local hash = crypto().sha256("abc");
            expect(hash.len()).to.equal(32);
        });
    });

    describe("imp timers (common.stub)", function() {

        it("keeps an un-fired named timer across a sleep and fires the due one", function() {
            imp.stub.resetTimer();

            local farFired = false;
            local nearFired = false;
            imp.wakeup(1000, function() { farFired = true; }, "far");
            imp.wakeup(0.01, function() { nearFired = true; }, "near");

            imp.sleep(0.02);

            expect(nearFired).toBeTruthy();
            expect(farFired).toBeFalsy();
            expect("far" in imp.timerTable).toBeTruthy();
            expect("near" in imp.timerTable).toBeFalsy();
        });
    });

    describe("fixedfrequencydac (device.stub)", function() {

        it("stores the buffer passed to addbuffer", function() {
            local dac = fixedfrequencydac();
            local buf = blob(4);
            dac.addbuffer(buf);

            expect(dac.getLastAddbufferNewBuffer()).to.equal(buf);
        });
    });

    describe("KiwiJSONParser", function() {

        it("throws on a duplicate key among several", function() {
            // Pre-fix, the `break` sat outside the `if`, so only the first-iterated
            // existing key was ever compared — duplicate detection was unreliable
            // for any key the table happened not to iterate first. The fix scans all keys.
            local threw = false;
            try {
                KiwiJSONParser.parse("{\"a\":1,\"b\":2,\"a\":3}");
            } catch (e) {
                threw = true;
            }
            expect(threw).toBeTruthy();
        });

        it("still parses a well-formed object", function() {
            local parsed = KiwiJSONParser.parse("{\"a\":1,\"b\":2}");
            expect(parsed.a).to.equal(1);
            expect(parsed.b).to.equal(2);
        });
    });
});
