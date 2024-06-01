extern int eval_l(int num);
extern int eval_r(int num);

int compute(int num) {
    return eval_l(num) * eval_r(num);
}

