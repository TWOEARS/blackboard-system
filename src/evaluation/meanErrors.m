function errors = meanErrors( errors )

errors(1).trueposTime = sum([errors.trueposTime]);
errors(1).condposTime = sum([errors.condposTime]);
errors(1).condnegTime = sum([errors.condnegTime]);
errors(1).testposTime = sum([errors.testposTime]);
errors(1).truenegTime = sum([errors.truenegTime]);
errors(1).testnegTime = sum([errors.testnegTime]);
errors(2:end) = [];
errors.sensitivity = errors.trueposTime / errors.condposTime;
errors.pospredval = errors.trueposTime / errors.testposTime;
errors.specificity = errors.truenegTime / errors.condnegTime;
errors.negpredval = errors.truenegTime / errors.testnegTime;
errors.acc = (errors.trueposTime + errors.truenegTime) / ...
    (errors.condposTime + errors.condnegTime);
