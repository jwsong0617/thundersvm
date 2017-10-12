//
// Created by jiashuai on 17-10-6.
//

#include <thundersvm/model/oneclass_svc.h>


void OneClassSVC::train(DataSet dataset, SvmParam param) {
    int n_instances = dataset.total_count();
    SyncData<real> alpha(n_instances);
    SyncData<real> f_val(n_instances);

    KernelMatrix kernelMatrix(dataset.instances(), param.gamma);

    alpha.mem_set(0);
    int n = static_cast<int>(param.nu * n_instances);
    for (int i = 0; i < n; ++i) {
        alpha[i] = 1;
    }
    if (n < n_instances)
        alpha[n] = param.nu * n_instances - n;
    int ws_size = min(min(max2power(n), max2power(n_instances - n)) * 2, 1024);

    //init_f
    //TODO batch, thrust
    SyncData<int> idx(1);
    SyncData<real> kernel_row(n_instances);
    f_val.mem_set(0);
    for (int i = 0; i <= n; ++i) {
        idx[0] = i;
        kernelMatrix.get_rows(idx, kernel_row);
        for (int j = 0; j < n_instances; ++j) {
            f_val[j] += alpha[i] * kernel_row[j];
        }
    }

    SyncData<int> y(n_instances);
    for (int i = 0; i < n_instances; ++i) {
        y[i] = 1;
    }
    smo_solver(kernelMatrix, y, alpha, rho, f_val, param.epsilon, 1, ws_size);

    record_model(alpha, y, dataset.instances(), param);
}

vector<real> OneClassSVC::predict(const DataSet::node2d &instances, int batch_size) {
    vector<real> dec_values = SvmModel::predict(instances, batch_size);
    vector<real> predict_y;
    for (int i = 0; i < dec_values.size(); ++i) {
        predict_y.push_back(dec_values[i] > 0 ? 1 : -1);
    }
    return predict_y;
}

void OneClassSVC::save_to_file(string path) {

}

void OneClassSVC::load_from_file(string path) {

}


