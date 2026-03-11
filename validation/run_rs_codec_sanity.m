function result = run_rs_codec_sanity()
%RUN_RS_CODEC_SANITY Standalone no-noise RS codec sanity check.

    test_bits = randi([0 1], 223 * 8 * 10, 1);
    coded_bits = RS_Encode(test_bits, 255, 223, 8);
    decoded_bits = RS_Decode(coded_bits, 255, 223, 8, length(test_bits));
    ber = sum(abs(decoded_bits - test_bits)) / length(test_bits);

    result = struct();
    result.ber = ber;
    result.passed = (ber == 0);
    result.num_bits = length(test_bits);
end
