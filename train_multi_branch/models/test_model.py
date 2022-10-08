from torch.autograd import Variable
from collections import OrderedDict
import util.util as util
from .base_model import BaseModel
from . import networks
import torch

class TestModel(BaseModel):
    def name(self):
        return 'TestModel'

    def initialize(self, opt):
        assert(not opt.isTrain)
        with torch.no_grad():
            BaseModel.initialize(self, opt)
            self.input_A = self.Tensor(opt.batchSize, opt.input_nc, opt.fineSize, opt.fineSize)

            self.netG = networks.define_G(opt.input_nc, opt.output_nc, opt.ngf,
                                          opt.which_model_netG, opt.norm, not opt.no_dropout, self.gpu_ids, False,
                                          opt.learn_residual, opt.layers)
            which_epoch = opt.which_epoch
            self.load_network(self.netG, 'G', which_epoch)

        print('---------- Networks initialized -------------')
        networks.print_network(self.netG)
        print('-----------------------------------------------')

    def set_input(self, input):
        # we need to use single_dataset mode
        with torch.no_grad():
            input_A = input['A']
            temp = self.input_A.clone()
            temp.resize_(input_A.size()).copy_(input_A)
            self.input_A = temp
            self.image_paths = input['A_paths']

    def test(self):
        with torch.no_grad():
            self.real_A = self.input_A
            self.fake_B = self.netG.forward(self.real_A).detach()

    # get image paths
    def get_image_paths(self):
        return self.image_paths

    def get_current_visuals(self):
        real_A = util.tensor2im(self.real_A.data)
        fake_B = util.tensor2im(self.fake_B.data)
        del self.real_A, self.fake_B
        return OrderedDict([('real_A', real_A), ('fake_B', fake_B)])
