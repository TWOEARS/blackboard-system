function val = libsvmCVext(y, x, param, nr_fold, bestVal)
len = length(y);
rand_ind = randperm(len);
dec_values = [];
labels = [];
for i = 1:nr_fold % Cross training : folding
  test_ind = rand_ind([floor((i-1)*len/nr_fold)+1:floor(i*len/nr_fold)]');
  train_ind = [1:len]';
  train_ind(test_ind) = [];
  model = libsvmtrain(y(train_ind),x(train_ind,:),param);
  [pred, acc, dec] = libsvmpredict(y(test_ind),x(test_ind,:),model);
  if model.Label(1) < 0;
    dec = dec * -1;
  end
  dec_values = vertcat(dec_values, dec);
  labels = vertcat(labels, y(test_ind));
  disp( sprintf( 'Validation value after run %d:', i ) );
  val = validation_function(dec_values, labels);
  if (i < nr_fold)  &&  ((val*i + 1*(nr_fold-i))/nr_fold <= bestVal)
      disp( 'CV run cannot reach best value any more, aborting' );
      break;
  end
end
