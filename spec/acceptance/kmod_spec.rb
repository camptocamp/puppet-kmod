# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'kmod' do
  context 'with defines set to present' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<~PUPPET
          kmod::alias { 'bond0':
            source => 'bonding',
          }
          kmod::blacklist { 'pcspkr': }
          kmod::install { 'dccp': }
          kmod::option { 'bonding mode':
            module => 'bonding',
            option => 'mode',
            value  => '1',
          }
        PUPPET
      end
    end

    describe file('/etc/modprobe.d/bond0.conf') do
      its(:content) { is_expected.to match %r{^alias bond0 bonding$} }
    end

    describe file('/etc/modprobe.d/blacklist.conf') do
      its(:content) { is_expected.to match %r{^blacklist pcspkr$} }
    end

    describe file('/etc/modprobe.d/dccp.conf') do
      its(:content) { is_expected.to match %r{^install dccp /bin/true$} }
    end

    describe file('/etc/modprobe.d/bonding.conf') do
      its(:content) { is_expected.to match %r{^options bonding mode=1$} }
    end
  end

  context 'with defines set to absent' do
    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<~PUPPET
          kmod::alias { 'bond0':
            ensure => absent,
            source => 'bonding',
          }
          kmod::blacklist { 'pcspkr':
            ensure => absent,
          }
          kmod::install { 'dccp':
            ensure => absent,
          }
          kmod::option { 'bonding mode':
            ensure => absent,
            module => 'bonding',
            option => 'mode',
            value  => '1',
          }
        PUPPET
      end
    end

    describe file('/etc/modprobe.d/bond0.conf') do
      its(:content) { is_expected.not_to match %r{bond0} }
    end

    describe file('/etc/modprobe.d/blacklist.conf') do
      its(:content) { is_expected.not_to match %r{pcspkr} }
    end

    describe file('/etc/modprobe.d/dccp.conf') do
      its(:content) { is_expected.not_to match %r{dccp} }
    end

    describe file('/etc/modprobe.d/bonding.conf') do
      its(:content) { is_expected.not_to match %r{bonding} }
    end
  end

  context 'with one of several options set to absent' do
    before(:all) do
      on(default, "echo 'options bonding mode=1 miimon=100' > /etc/modprobe.d/bonding.conf")
    end

    it_behaves_like 'an idempotent resource' do
      let(:manifest) do
        <<~PUPPET
          kmod::option { 'bonding mode':
            ensure => absent,
            module => 'bonding',
            option => 'mode',
            value  => '1',
          }
        PUPPET
      end
    end

    describe file('/etc/modprobe.d/bonding.conf') do
      its(:content) { is_expected.to match %r{^options bonding miimon=100$} }
    end
  end

  # Use a module the host already has loaded, since containers cannot load anything
  context 'with kmod::load' do
    # EL ships /etc/modules-load.d in systemd-udev which is missing from the container
    before(:all) do
      install_package(default, 'systemd-udev') if fact('os.family') == 'RedHat'
    end

    it_behaves_like 'an idempotent resource' do
      let(:manifest) { "kmod::load { 'overlay': }" }
    end

    describe file('/etc/modules-load.d/overlay.conf') do
      its(:content) { is_expected.to match %r{^overlay$} }
    end
  end
end
