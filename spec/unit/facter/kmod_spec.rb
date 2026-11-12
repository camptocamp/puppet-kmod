# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require_relative '../../../lib/facter/util/kmod'

describe 'kmods fact' do
  subject(:fact) { Facter.fact(:kmods).value }

  let(:tmpdir) { Dir.mktmpdir('kmod') }
  let(:modules_load_d) { File.join(tmpdir, 'modules-load.d') }
  let(:sys_module) { File.join(tmpdir, 'sys', 'module') }
  let(:header) { Facter::Util::Kmod::MANAGED_HEADER }

  def declare(file, *modules, managed: true)
    FileUtils.mkdir_p(modules_load_d)
    lines = managed ? [header] : ['# written by someone else']
    File.write(File.join(modules_load_d, file), "#{(lines + modules).join("\n")}\n")
  end

  def load_module(name, parameters: {}, holders: [])
    dir = File.join(sys_module, name)
    FileUtils.mkdir_p(dir)
    FileUtils.mkdir_p(File.join(dir, 'parameters')) unless parameters.empty?
    parameters.each { |param, value| File.write(File.join(dir, 'parameters', param), "#{value}\n") }
    FileUtils.mkdir_p(File.join(dir, 'holders')) unless holders.empty?
    holders.each { |holder| FileUtils.mkdir_p(File.join(dir, 'holders', holder)) }
  end

  before do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
    stub_const('Facter::Util::Kmod::MODULES_LOAD_D', modules_load_d)
    stub_const('Facter::Util::Kmod::SYS_MODULE', sys_module)
  end

  after { FileUtils.rm_rf(tmpdir) }

  context 'without /sys/module' do
    before { declare('overlay.conf', 'overlay') }

    it { is_expected.to be_nil }
  end

  context 'without /etc/modules-load.d' do
    before { FileUtils.mkdir_p(sys_module) }

    it { is_expected.to eq({}) }
  end

  context 'with a declared and loaded module' do
    before do
      declare('br-netfilter.conf', 'br-netfilter')
      load_module('br_netfilter', parameters: { 'foo' => 'bar', 'secret' => 'x' }, holders: %w[nf_conntrack])
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(File.join(sys_module, 'br_netfilter', 'parameters', 'secret')).and_raise(Errno::EIO)
    end

    it 'reports it under its kernel name with parameters and holders, skipping unreadable parameters' do
      expect(fact).to eq(
        'br_netfilter' => {
          'parameters' => { 'foo' => 'bar' },
          'used_by' => %w[nf_conntrack],
        },
      )
    end
  end

  context 'with a loaded module that has no parameters or holders' do
    before do
      declare('overlay.conf', 'overlay')
      load_module('overlay')
    end

    it { is_expected.to eq('overlay' => { 'parameters' => {}, 'used_by' => [] }) }
  end

  context 'with a declared module that is not loaded' do
    before do
      declare('missing.conf', 'missing')
      declare('overlay.conf', 'overlay')
      load_module('overlay')
    end

    it 'leaves it out' do
      expect(fact.keys).to eq(%w[overlay])
    end
  end

  context 'with a modules-load.d file not written by kmod::load' do
    before do
      declare('k8s.conf', 'overlay', managed: false)
      load_module('overlay')
      load_module('k8s')
    end

    it { is_expected.to eq({}) }
  end

  context 'with a managed file listing several modules, comments and blank lines' do
    before do
      declare('many.conf', '', '# comment', '; comment', 'overlay', 'overlay', ' br_netfilter ')
      load_module('overlay')
      load_module('br_netfilter')
    end

    it 'reports each module once' do
      expect(fact.keys).to contain_exactly('overlay', 'br_netfilter')
    end
  end
end
