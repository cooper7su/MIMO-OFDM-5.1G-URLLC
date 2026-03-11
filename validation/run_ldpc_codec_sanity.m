function result = run_ldpc_codec_sanity(cfg)
%RUN_LDPC_CODEC_SANITY Standalone no-noise LDPC codec sanity check.

    load(cfg.ldpc_validation_matrix_path, 'H_parity');
    H_parity = sparse(H_parity);
    [hEnc, hDec] = CreateLDPCObjects(H_parity, cfg.ldpc_max_iterations);

    [m, n] = size(H_parity);
    ldpc_k = n - m;
    ldpc_n = n;

    test_length = 5000;
    test_bits = randi([0 1], test_length, 1);
    [coded_bits, original_length, coded_meta] = LDPC_Encode(test_bits, hEnc, ldpc_k);
    coded_indices = coded_meta.coded_indices;

    received_llr = zeros(size(coded_bits));
    received_llr(coded_indices) = (1 - 2 * coded_bits(coded_indices)) * 20;
    non_coded_indices = setdiff(1:length(coded_bits), coded_indices);
    received_llr(non_coded_indices) = (1 - 2 * coded_bits(non_coded_indices)) * 10;

    decoded_bits = LDPC_Decode(received_llr, hDec, ldpc_n, ldpc_k, original_length, coded_meta);
    ber_total = sum(abs(decoded_bits - test_bits)) / length(test_bits);
    ber_coded = sum(abs(decoded_bits(coded_indices) - test_bits(coded_indices))) / length(coded_indices);

    result = struct();
    result.ber_total = ber_total;
    result.ber_coded = ber_coded;
    result.passed = (ber_total == 0);
    result.test_length = test_length;
end
