# frozen_string_literal: true

require 'spec_helper'

describe 'kmod::blacklist', type: :define do
  let(:title) { 'foo' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(augeasversion: '1.2.0')
      end

      context 'when ensure is set to present' do
        let(:params) { { ensure: 'present', file: '/bar/baz' } }

        it { is_expected.to contain_kmod__blacklist('foo') }

        it {
          is_expected.to contain_kmod__setting('kmod::blacklist foo')
            .with('ensure' => 'present',
                  'category' => 'blacklist',
                  'module' => 'foo',
                  'file' => '/bar/baz')
        }
      end

      context 'when file is not specified' do
        let(:params) { { ensure: 'present' } }

        it { is_expected.to contain_kmod__blacklist('foo') }

        it {
          is_expected.to contain_kmod__setting('kmod::blacklist foo')
            .with('ensure' => 'present',
                  'category' => 'blacklist',
                  'module' => 'foo',
                  'file' => '/etc/modprobe.d/blacklist.conf')
        }
      end

      context 'when ensure is set to absent' do
        let(:params) { { ensure: 'absent', file: '/bar/baz' } }

        it { is_expected.to contain_kmod__blacklist('foo') }

        it {
          is_expected.to contain_kmod__setting('kmod::blacklist foo')
            .with('ensure' => 'absent',
                  'category' => 'blacklist',
                  'module' => 'foo',
                  'file' => '/bar/baz')
        }

        it {
          is_expected.to contain_kmod__setting('kmod::blacklist foo install')
            .with('ensure' => 'absent',
                  'category' => 'install',
                  'module' => 'foo',
                  'file' => '/bar/baz')
        }
      end

      context 'when using defaults' do
        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_kmod__setting('kmod::blacklist foo install')
            .with('ensure' => 'present',
                  'category' => 'install',
                  'module' => 'foo',
                  'option' => 'command',
                  'value' => '/bin/false',
                  'file' => '/etc/modprobe.d/blacklist.conf')
        }
      end

      context 'when file permissions are specified' do
        let(:params) { { file: '/bar/baz' } }
        let(:pre_condition) do
          <<~END
            class { 'kmod':
              owner     => 'adm',
              group     => 'sys',
              file_mode => '0600',
            }
          END
        end

        it { is_expected.to contain_kmod__blacklist('foo') }

        it {
          is_expected.to contain_file(params[:file])
            .with(
              'owner' => 'adm',
              'group' => 'sys',
              'mode' => '0600',
            )
        }
      end
    end
  end
end
