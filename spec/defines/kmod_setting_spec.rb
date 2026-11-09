# frozen_string_literal: true

require 'spec_helper'

describe 'kmod::setting', type: :define do
  let(:title) { 'foo' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(augeasversion: '1.2.0')
      end

      let(:default_params) { { file: '/etc/modprobe.conf' } }
      let(:params) { default_params }

      context 'add an alias' do
        let(:params) { default_params.merge(category: 'alias', option: 'modulename', value: 'tango') }

        it { is_expected.to contain_kmod__setting('foo') }

        it {
          is_expected.to contain_augeas('kmod::setting foo foo')
            .with('incl' => '/etc/modprobe.conf',
                  'lens' => 'Modprobe.lns',
                  'changes' => ["set alias[. = 'foo'] foo", "set alias[. = 'foo']/modulename tango"],
                  'require' => 'File[/etc/modprobe.conf]')
        }
      end

      context 'add a blacklist' do
        let(:params) { { file: '/etc/modprobe.d/blacklist.conf', category: 'blacklist' } }

        it { is_expected.to contain_kmod__setting('foo') }

        it {
          is_expected.to contain_augeas('kmod::setting foo foo')
            .with('incl' => '/etc/modprobe.d/blacklist.conf',
                  'lens' => 'Modprobe.lns',
                  'changes' => ["set blacklist[. = 'foo'] foo"],
                  'require' => 'File[/etc/modprobe.d/blacklist.conf]')
        }
      end

      context 'remove an option' do
        let(:params) { default_params.merge(ensure: 'absent', category: 'options', option: 'mode', value: '1') }

        it {
          is_expected.to contain_augeas('kmod::setting foo foo')
            .with_changes(["rm options[. = 'foo']/mode", "rm options[. = 'foo'][count(*[label() != '#comment']) = 0]"])
        }
      end

      context 'remove an alias' do
        let(:params) { default_params.merge(ensure: 'absent', category: 'alias', option: 'modulename', value: 'tango') }

        it { is_expected.to contain_augeas('kmod::setting foo foo').with_changes("rm alias[. = 'foo']") }
      end

      context 'add an install with file permissions specified' do
        let(:params) do
          default_params.merge(
            category: 'install',
            option: 'command',
            value: '/bin/true',
          )
        end
        let(:pre_condition) do
          <<~END
            class { 'kmod':
              owner     => 'adm',
              group     => 'sys',
              file_mode => '0600',
            }
          END
        end

        it { is_expected.to contain_kmod__setting('foo') }

        it {
          is_expected.to contain_augeas('kmod::setting foo foo')
            .with('incl' => '/etc/modprobe.conf',
                  'lens' => 'Modprobe.lns',
                  'changes' => ["set install[. = 'foo'] foo", "set install[. = 'foo']/command /bin/true"],
                  'require' => 'File[/etc/modprobe.conf]')
        }

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
