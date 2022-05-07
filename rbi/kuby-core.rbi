# typed: strong
class KubyGenerator < Rails::Generators::Base
  sig { returns(T.untyped) }
  def create_initializer_file; end

  sig { returns(T.untyped) }
  def create_config_file; end

  sig { returns(T.untyped) }
  def create_dockerignore; end

  sig { returns(T.untyped) }
  def app_name; end
end

module Kuby
  VERSION = '0.17.0'.freeze

  class BasicLogger < Logger
    extend T::Sig

    sig do
      override.params(
        logdev: T.any(String, IO, StringIO, NilClass),
        shift_age: Integer,
        shift_size: Integer,
        level: Integer,
        progname: T.nilable(String),
        formatter: T.nilable(FormatterProcType),
        datetime_format: T.nilable(String),
        shift_period_suffix: T.nilable(String)
      ).void
    end
    def initialize(logdev, shift_age = 0, shift_size = 1048576, level: DEBUG, progname: nil, formatter: nil, datetime_format: nil, shift_period_suffix: '%Y%m%d'); end

    sig { override.params(progname_or_msg: T.untyped, block: T.nilable(T.proc.returns(T.untyped))).void }
    def info(progname_or_msg = nil, &block); end

    sig { override.params(progname_or_msg: T.untyped, block: T.nilable(T.proc.returns(T.untyped))).void }
    def fatal(progname_or_msg = nil, &block); end

    sig { params(out: T.any(IO, StringIO), err: T.any(IO, StringIO), block: T.proc.void).void }
    def with_pipes(out = STDOUT, err = STDERR, &block); end

    sig { returns(T.nilable(Process::Status)) }
    def last_status; end
  end

  class CLIBase
    extend T::Sig
    BeforeCallback = T.type_alias { T.proc.params(cmd: T::Array[String]).void }
    AfterCallback = T.type_alias { T.proc.params(cmd: T::Array[String], last_status: T.nilable(Process::Status)).void }

    sig { returns(T.nilable(Process::Status)) }
    def last_status; end

    sig { params(block: BeforeCallback).void }
    def before_execute(&block); end

    sig { params(block: AfterCallback).void }
    def after_execute(&block); end

    sig { params(out: T.any(IO, StringIO), err: T.any(IO, StringIO), block: T.proc.void).void }
    def with_pipes(out = STDOUT, err = STDERR, &block); end

    sig { returns(T.nilable(T.any(IO, StringIO))) }
    def stdout; end

    sig { params(new_stdout: T.nilable(T.any(IO, StringIO))).void }
    def stdout=(new_stdout); end

    sig { returns(T.nilable(T.any(IO, StringIO))) }
    def stderr; end

    sig { params(new_stderr: T.nilable(T.any(IO, StringIO))).void }
    def stderr=(new_stderr); end

    sig { params(cmd: T::Array[String], block: T.proc.params(stdin: IO).void).void }
    def open3_w(cmd, &block); end

    sig { params(cmd: T::Array[String]).void }
    def execc(cmd); end

    sig { params(cmd: T::Array[String]).void }
    def systemm(cmd); end

    sig { params(cmd: T::Array[String]).void }
    def systemm_default(cmd); end

    sig { params(cmd: T::Array[String]).void }
    def systemm_open3(cmd); end

    sig { params(cmd: T::Array[String]).returns(String) }
    def backticks(cmd); end

    sig { params(cmd: T::Array[String]).returns(String) }
    def backticks_default(cmd); end

    sig { params(cmd: T::Array[String]).returns(String) }
    def backticks_open3(cmd); end

    sig { params(cmd: T::Array[String]).void }
    def run_before_callbacks(cmd); end

    sig { params(cmd: T::Array[String]).void }
    def run_after_callbacks(cmd); end

    sig { params(status: Process::Status).void }
    def last_status=(status); end

    sig { returns(Symbol) }
    def status_key; end

    sig { returns(Symbol) }
    def stdout_key; end

    sig { returns(Symbol) }
    def stderr_key; end
  end

  class Commands
    extend T::Sig
    extend GLI::App

    sig { returns(Kuby::Tasks) }
    def self.tasks; end

    sig { params(global_options: T::Hash[T.any(String, Symbol), T.any(String, Integer)]).void }
    def self.load_kuby_config!(global_options); end
  end

  class Definition
    extend T::Sig

    sig { returns(String) }
    attr_reader :app_name

    sig { params(app_name: String, block: T.nilable(T.proc.void)).void }
    def initialize(app_name, &block); end

    sig { params(name: Symbol, block: T.nilable(T.proc.void)).returns(Kuby::Environment) }
    def environment(name = Kuby.env, &block); end

    sig { returns(T::Hash[Symbol, Kuby::Environment]) }
    def environments; end
  end

  class Dependable
    sig { returns(T.untyped) }
    attr_reader :name

    sig { returns(T.untyped) }
    attr_reader :version_or_callable

    sig { params(name: T.untyped, version_or_callable: T.untyped).void }
    def initialize(name, version_or_callable); end

    sig { returns(T.untyped) }
    def version; end
  end

  class Dependency
    sig { returns(T.untyped) }
    attr_reader :name

    sig { returns(T.untyped) }
    attr_reader :constraints

    sig { params(name: T.untyped, constraints: T.untyped).void }
    def initialize(name, *constraints); end

    sig { params(dependable: T.untyped).returns(T.untyped) }
    def satisfied_by?(dependable); end
  end

  class Environment
    sig { returns(T.untyped) }
    attr_reader :name

    sig { returns(T.untyped) }
    attr_reader :definition

    sig { returns(T.untyped) }
    attr_accessor :configured

    sig { params(name: T.untyped, definition: T.untyped, block: T.untyped).void }
    def initialize(name, definition, &block); end

    sig { params(block: T.untyped).returns(T.untyped) }
    def docker(&block); end

    sig { params(block: T.untyped).returns(T.untyped) }
    def kubernetes(&block); end

    sig { returns(T.untyped) }
    def app_name; end
  end

  class Plugin
    sig { returns(T.untyped) }
    attr_reader :environment

    sig { params(environment: T.untyped).void }
    def initialize(environment); end

    sig { returns(T.untyped) }
    def self.task_dirs; end

    sig { params(dependable_name: T.untyped, constraints: T.untyped).returns(T.untyped) }
    def self.depends_on(dependable_name, *constraints); end

    sig { returns(T.untyped) }
    def self.dependencies; end

    sig { params(block: T.untyped).returns(T.untyped) }
    def configure(&block); end

    sig { returns(T.untyped) }
    def setup; end

    sig { returns(T.untyped) }
    def remove; end

    sig { returns(T.untyped) }
    def resources; end

    sig { returns(T.untyped) }
    def docker_images; end

    sig { returns(T.untyped) }
    def after_configuration; end

    sig { returns(T.untyped) }
    def before_setup; end

    sig { returns(T.untyped) }
    def after_setup; end

    sig { params(manifest: T.untyped).returns(T.untyped) }
    def before_deploy(manifest); end

    sig { params(manifest: T.untyped).returns(T.untyped) }
    def after_deploy(manifest); end

    sig { returns(T.untyped) }
    def after_initialize; end
  end

  class PluginRegistry
    include Enumerable
    ANY = 'any'.freeze

    sig { params(plugin_name: T.untyped, plugin_klass: T.untyped, environment: T.untyped).returns(T.untyped) }
    def register(plugin_name, plugin_klass, environment: ANY); end

    sig { params(plugin_name: T.untyped, environment: T.untyped).returns(T.untyped) }
    def find(plugin_name, environment: Kuby.env); end

    sig { params(block: T.untyped).returns(T.untyped) }
    def each(&block); end

    sig { returns(T.untyped) }
    def plugins; end
  end

  class Tasks
    sig { returns(T.untyped) }
    attr_reader :environment

    sig { params(environment: T.untyped).void }
    def initialize(environment); end

    sig { params(only: T.untyped).returns(T.untyped) }
    def print_dockerfiles(only: []); end

    sig { params(only: T.untyped).returns(T.untyped) }
    def setup(only: []); end

    sig { params(name: T.untyped).returns(T.untyped) }
    def remove_plugin(name); end

    sig { params(all: T.untyped).returns(T.untyped) }
    def list_plugins(all: false); end

    sig { params(tasks: T.untyped).returns(T.untyped) }
    def run_rake_tasks(tasks); end

    sig { returns(T.untyped) }
    def list_rake_tasks; end

    sig do
      params(
        build_args: T.untyped,
        docker_args: T.untyped,
        only: T.untyped,
        ignore_missing_args: T.untyped,
        context: T.untyped,
        cache_from_latest: T.untyped
      ).returns(T.untyped)
    end
    def build(build_args = {}, docker_args = [], only: [], ignore_missing_args: false, context: nil, cache_from_latest: true); end

    sig { params(only: T.untyped).returns(T.untyped) }
    def push(only: []); end

    sig { params(image: T.untyped).returns(T.untyped) }
    def push_image(image); end

    sig { params(tag: T.untyped).returns(T.untyped) }
    def deploy(tag = nil); end

    sig { returns(T.untyped) }
    def rollback; end

    sig { params(kind: T.untyped, name_pattern: T.untyped).returns(T.untyped) }
    def print_resources(kind = nil, name_pattern = nil); end

    sig { returns(T.untyped) }
    def print_kubeconfig; end

    sig { returns(T.untyped) }
    def print_images; end

    sig { params(cmd: T.untyped).returns(T.untyped) }
    def kubectl(*cmd); end

    sig { returns(T.untyped) }
    def remote_logs; end

    sig { returns(T.untyped) }
    def remote_status; end

    sig { params(cmd: T.untyped).returns(T.untyped) }
    def remote_exec(cmd); end

    sig { params(cmd: T.untyped).returns(T.untyped) }
    def remote_system(cmd); end

    sig { returns(T.untyped) }
    def remote_shell; end

    sig { returns(T.untyped) }
    def remote_console; end

    sig { returns(T.untyped) }
    def remote_dbconsole; end

    sig { returns(T.untyped) }
    def remote_restart; end

    sig { params(docker_args: T.untyped).returns(T.untyped) }
    def check_platform(docker_args); end

    sig { params(build_args: T.untyped).returns(T.untyped) }
    def check_build_args(build_args); end

    sig { params(image: T.untyped).returns(T.untyped) }
    def perform_docker_login_if_necessary(image); end

    sig { returns(T.untyped) }
    def get_first_pod; end

    sig { returns(T.untyped) }
    def namespace; end

    sig { returns(T.untyped) }
    def match_labels; end

    sig { returns(T.untyped) }
    def rails_app; end

    sig { returns(T.untyped) }
    def kubernetes_cli; end

    sig { returns(T.untyped) }
    def helm_cli; end

    sig { returns(T.untyped) }
    def docker_cli; end

    sig { returns(T.untyped) }
    def kubernetes; end

    sig { returns(T.untyped) }
    def docker; end
  end

  class TrailingHash < Hash
    sig { params(block: T.untyped).returns(T.untyped) }
    def each(&block); end
  end

  module Docker
    LATEST_TAG = T.let('latest'.freeze, String)

    class Alpine < Distro
      SHELL_EXE = T.let('/bin/sh'.freeze, String)
      DEFAULT_PACKAGES = T.let([
        [:ca_certificates, nil],
        [:nodejs, '12.14.1'],
        [:yarn, '1.21.1'],
        [:c_toolchain, nil],
        [:tzdata, nil],
        [:git, nil]
      ].freeze, T::Array[[Symbol, T.nilable(String)]])

      sig { returns(Layer) }
      attr_reader :phase

      sig { override.params(packages: T::Array[Distro::PackageImpl], into: Dockerfile).void }
      def install(packages, into:); end

      sig { override.returns(T::Array[[Symbol, T.nilable(String)]]) }
      def default_packages; end

      sig { override.returns(String) }
      def shell_exe; end

      sig { params(packages: T::Array[Distro::PackageImpl], dockerfile: Dockerfile).void }
      def install_managed(packages, dockerfile); end

      sig { params(packages: T::Array[Distro::PackageImpl], dockerfile: Dockerfile).void }
      def install_unmanaged(packages, dockerfile); end
    end

    class AppImage < ::Kuby::Docker::TimestampedImage
      extend T::Sig

      sig do
        params(
          dockerfile: T.any(Dockerfile, T.proc.returns(Dockerfile)),
          image_url: String,
          credentials: Credentials,
          registry_index_url: T.nilable(String),
          main_tag: T.nilable(String),
          alias_tags: T::Array[String]
        ).void
      end
      def initialize(dockerfile, image_url, credentials, registry_index_url = nil, main_tag = nil, alias_tags = []); end
    end

    class AppPhase < Layer
      extend T::Sig

      sig { params(environment: Environment).void }
      def initialize(environment); end

      sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile); end

      sig { params(key: String, value: String).void }
      def env(key, value); end
    end

    class AssetsPhase < Layer
      extend T::Sig

      sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile); end
    end

    class BundlerPhase < Layer
      extend T::Sig
      DEFAULT_GEMFILE = T.let('Gemfile'.freeze, String)
      DEFAULT_WITHOUT = T.let(
        ['development', 'test', 'deploy'].freeze, T::Array[String]
      )

      sig { returns(T.nilable(String)) }
      attr_reader :version

      sig { params(version: String).returns(String) }
      attr_writer :version

      sig { returns(T.nilable(String)) }
      attr_reader :gemfile

      sig { params(gemfile: String).returns(String) }
      attr_writer :gemfile

      sig { returns(T.nilable(T::Array[String])) }
      attr_reader :without

      sig { params(without: T::Array[String]).returns(T::Array[String]) }
      attr_writer :without

      sig { returns(T.nilable(String)) }
      attr_reader :executable

      sig { params(executable: String).returns(String) }
      attr_writer :executable

      sig { params(environment: Environment).void }
      def initialize(environment); end

      sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile); end

      sig { params(paths: String).void }
      def gemfiles(*paths); end

      sig { returns(String) }
      def default_version; end
    end

    class CLI < CLIBase
      extend T::Sig

      sig { returns(String) }
      attr_reader :executable

      sig { params(executable: T.nilable(String)).void }
      def initialize(executable = nil); end

      sig { returns(T.nilable(String)) }
      def config_file; end

      sig { returns(String) }
      def default_config_file; end

      sig { params(url: String, username: String, password: String).void }
      def login(url:, username:, password:); end

      sig { returns(T::Array[String]) }
      def auths; end

      sig do
        params(
          image: Image,
          build_args: T::Hash[T.any(Symbol, String), String],
          docker_args: T::Array[String],
          context: T.nilable(String),
          cache_from: T.nilable(String)
        ).void
      end
      def build(image, build_args: {}, docker_args: [], context: nil, cache_from: nil); end

      sig do
        params(
          image_url: String,
          tag: String,
          env: T::Hash[T.any(Symbol, String), String],
          ports: T::Array[T.any(String, Integer)]
        ).void
      end
      def run(image_url:, tag: 'latest', env: {}, ports: []); end

      sig { params(container: String, command: String, tty: T::Boolean).returns(String) }
      def exec_capture(container:, command:, tty: true); end

      sig { params(image_url: String, tag: String, format: T.nilable(String)).returns(String) }
      def inspect(image_url:, tag: 'latest', format: nil); end

      sig { params(image_url: String, digests: T::Boolean).returns(T::Array[T::Hash[Symbol, String]]) }
      def images(image_url, digests: true); end

      sig { params(image_url: String, tag: String).void }
      def push(image_url, tag); end

      sig { params(image_url: String, tag: String).void }
      def pull(image_url, tag); end

      sig { returns(Symbol) }
      def status_key; end

      sig { returns(Symbol) }
      def stdout_key; end

      sig { returns(Symbol) }
      def stderr_key; end
    end

    class CopyPhase < Layer
      extend T::Sig
      DEFAULT_PATHS = T.let(['./'].freeze, T::Array[String])

      sig { returns(T::Array[String]) }
      attr_reader :paths

      sig { params(environment: Environment).void }
      def initialize(environment); end

      sig { params(path: String).void }
      def <<(path); end

      sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile); end
    end

    class Credentials
      extend ::KubeDSL::ValueFields
    end

    class Debian < Distro
      SHELL_EXE = T.let('/bin/bash'.freeze, String)
      DEFAULT_PACKAGES = T.let([
        [:ca_certificates, nil],
        [:nodejs, '12.14.1'],
        [:yarn, '1.21.1']
      ].freeze, T::Array[[Symbol, T.nilable(String)]])

      sig { returns(Layer) }
      attr_reader :phase

      sig { override.params(packages: T::Array[Distro::PackageImpl], into: Dockerfile).void }
      def install(packages, into:); end

      sig { override.returns(T::Array[[Symbol, T.nilable(String)]]) }
      def default_packages; end

      sig { override.returns(String) }
      def shell_exe; end

      sig { params(packages: T::Array[Distro::PackageImpl], dockerfile: Dockerfile).void }
      def install_managed(packages, dockerfile); end

      sig { params(packages: T::Array[Distro::PackageImpl], dockerfile: Dockerfile).void }
      def install_unmanaged(packages, dockerfile); end
    end

    class Distro
      abstract!

      extend T::Sig
      extend T::Helpers
      PackageImpl = T.type_alias { T.any(Packages::Package, Packages::ManagedPackage, Packages::SimpleManagedPackage) }
      ManagedPackageImpl = T.type_alias { T.any(Packages::ManagedPackage, Packages::SimpleManagedPackage) }

      sig { params(phase: Layer).void }
      def initialize(phase); end

      sig { params(packages: T::Array[PackageImpl], into: Dockerfile).void }
      def install(packages, into:); end

      sig { returns(T::Array[[Symbol, T.nilable(String)]]) }
      def default_packages; end

      sig { returns(String) }
      def shell_exe; end
    end

    class DockerURI
      extend T::Sig
      DEFAULT_REGISTRY_HOST = T.let('docker.io'.freeze, String)
      DEFAULT_REGISTRY_INDEX_HOST = T.let('index.docker.io'.freeze, String)
      DEFAULT_PORT = T.let(443, Integer)

      sig { params(url: String).returns(DockerURI) }
      def self.parse_uri(url); end

      sig { params(url: String).returns(DockerURI) }
      def self.parse_index_uri(url); end

      sig { params(url: String, default_host: T.nilable(String), default_port: T.nilable(Integer)).returns(DockerURI) }
      def self.parse(url, default_host:, default_port:); end

      sig { returns(String) }
      attr_reader :host

      sig { returns(Integer) }
      attr_reader :port

      sig { returns(String) }
      attr_reader :path

      sig { params(host: String, port: Integer, path: String).void }
      def initialize(host, port, path); end

      sig { returns(T::Boolean) }
      def has_default_port?; end
    end

    class Dockerfile
      extend T::Sig

      class Command
        extend T::Sig

        sig { returns(T::Array[T.any(String, Integer)]) }
        attr_reader :args

        sig { params(args: T::Array[T.any(String, Integer)]).void }
        def initialize(args); end

        sig { returns(String) }
        def to_s; end
      end

      class From < Command
        sig { returns(String) }
        attr_reader :image_url

        sig { returns(T.nilable(String)) }
        attr_reader :as

        sig { params(image_url: String, as: T.nilable(String)).void }
        def initialize(image_url, as: nil); end

        sig { returns(String) }
        def to_s; end
      end

      class Workdir < Command
        sig { returns(String) }
        def to_s; end
      end

      class Env < Command
        sig { returns(String) }
        def to_s; end
      end

      class Run < Command
        sig { returns(String) }
        def to_s; end
      end

      class Copy < Command
        sig { returns(String) }
        attr_reader :source

        sig { returns(String) }
        attr_reader :dest

        sig { returns(T.nilable(String)) }
        attr_reader :from

        sig { params(source: String, dest: String, from: T.nilable(String)).void }
        def initialize(source, dest, from: nil); end

        sig { returns(String) }
        def to_s; end
      end

      class Expose < Command
        sig { returns(String) }
        def to_s; end
      end

      class Cmd < Command
        sig { returns(String) }
        def to_s; end
      end

      class Arg < Command
        sig { returns(String) }
        def to_s; end
      end

      sig { returns(T::Array[Command]) }
      attr_reader :commands

      sig { returns(Integer) }
      attr_reader :cursor

      sig { void }
      def initialize; end

      sig { params(image_url: String, as: T.nilable(String)).void }
      def from(image_url, as: nil); end

      sig { params(args: String).void }
      def workdir(*args); end

      sig { params(args: String).void }
      def env(*args); end

      sig { params(args: String).void }
      def arg(*args); end

      sig { params(args: String).void }
      def run(*args); end

      sig { params(source: String, dest: String, from: T.nilable(String)).void }
      def copy(source, dest, from: nil); end

      sig { params(port: Integer).void }
      def expose(port); end

      sig { params(args: String).void }
      def cmd(*args); end

      sig { returns(String) }
      def to_s; end

      sig { returns(String) }
      def checksum; end

      sig { returns(T::Array[Integer]) }
      def exposed_ports; end

      sig { returns(T.nilable(String)) }
      def current_workdir; end

      sig { params(pos: Integer, block: T.proc.void).void }
      def insert_at(pos, &block); end

      sig { params(cmd: Command).void }
      def add(cmd); end
    end

    class BuildError < StandardError
    end

    class PushError < StandardError
    end

    class PullError < StandardError
    end

    class LoginError < StandardError
    end

    class MissingTagError < StandardError
    end

    class UnsupportedDistroError < StandardError
    end

    class MissingPackageError < StandardError
    end

    class MissingDistroError < StandardError
    end

    class Image
      extend T::Sig

      sig { returns(T.nilable(String)) }
      attr_reader :identifier

      sig { returns(String) }
      attr_reader :image_url

      sig { returns(T.nilable(String)) }
      attr_reader :registry_index_url

      sig { returns(Kuby::Docker::Credentials) }
      attr_reader :credentials

      sig { returns(T.nilable(String)) }
      attr_reader :main_tag

      sig { returns(T::Array[String]) }
      attr_reader :alias_tags

      sig do
        params(
          dockerfile: T.any(Dockerfile, T.proc.returns(Kuby::Docker::Dockerfile)),
          image_url: String,
          credentials: Kuby::Docker::Credentials,
          registry_index_url: T.nilable(String),
          main_tag: T.nilable(String),
          alias_tags: T::Array[String]
        ).void
      end
      def initialize(dockerfile, image_url, credentials, registry_index_url = nil, main_tag = nil, alias_tags = []); end

      sig { returns(Kuby::Docker::Image) }
      def new_version; end

      sig { returns(Kuby::Docker::Image) }
      def current_version; end

      sig { params(current_tag: T.nilable(String)).returns(Image) }
      def previous_version(current_tag = nil); end

      sig { returns(Kuby::Docker::Dockerfile) }
      def dockerfile; end

      sig { returns(String) }
      def image_host; end

      sig { returns(String) }
      def registry_index_host; end

      sig { returns(String) }
      def registry_index_hostname; end

      sig { returns(String) }
      def image_hostname; end

      sig { returns(String) }
      def image_repo; end

      sig { returns(Kuby::Docker::DockerURI) }
      def image_uri; end

      sig { returns(Kuby::Docker::DockerURI) }
      def registry_index_uri; end

      sig { returns(T::Array[String]) }
      def tags; end

      sig do
        params(
          build_args: T::Hash[String, String],
          docker_args: T::Array[String],
          context: T.nilable(String),
          cache_from: T.nilable(String)
        ).void
      end
      def build(build_args = {}, docker_args = [], context: nil, cache_from: nil); end

      sig { params(tag: String).void }
      def push(tag); end

      sig { params(tag: String).void }
      def pull(tag); end

      sig { returns(Kuby::Docker::CLI) }
      def docker_cli; end

      sig { params(main_tag: String, alias_tags: T::Array[String]).returns(Image) }
      def duplicate_with_tags(main_tag, alias_tags); end
    end

    class InlineLayer < Layer
      extend T::Sig

      sig { returns(T.proc.params(df: Dockerfile).void) }
      attr_reader :block

      sig { params(block: T.proc.params(df: Dockerfile).void).void }
      def initialize(block); end

      sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile); end
    end

    class Layer
      abstract!

      extend T::Sig
      extend T::Helpers

      sig { returns(Environment) }
      attr_reader :environment

      sig { params(environment: Environment).void }
      def initialize(environment); end

      sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile); end
    end

    class LayerStack
      include Enumerable
      extend T::Sig
      extend T::Generic
      Elem = type_member { { fixed: Kuby::Docker::Layer } }

      sig { returns(T::Array[Symbol]) }
      attr_reader :stack

      sig { returns(T::Hash[Symbol, Kuby::Docker::Layer]) }
      attr_reader :layers

      sig { void }
      def initialize; end

      sig { override.params(block: T.nilable(T.proc.params(layer: Kuby::Docker::Layer).void)).void }
      def each(&block); end

      sig { params(name: Symbol, layer: T.nilable(Layer), block: T.nilable(T.proc.params(df: Kuby::Docker::Dockerfile).void)).void }
      def use(name, layer = nil, &block); end

      sig do
        params(
          name: Symbol,
          layer: T.nilable(T.any(Layer, T::Hash[Symbol, T.untyped])),
          options: T::Hash[Symbol, T.untyped],
          block: T.nilable(T.proc.params(df: Kuby::Docker::Dockerfile).void)
        ).void
      end
      def insert(name, layer = nil, options = {}, &block); end

      sig { params(name: Symbol).void }
      def delete(name); end

      sig { params(name: Symbol).returns(T::Boolean) }
      def includes?(name); end
    end

    class LocalTags
      extend T::Sig

      sig { returns(Kuby::Docker::CLI) }
      attr_reader :cli

      sig { returns(String) }
      attr_reader :image_url

      sig { params(cli: Kuby::Docker::CLI, image_url: String).void }
      def initialize(cli, image_url); end

      sig { returns(T::Array[String]) }
      def tags; end

      sig { returns(T::Array[String]) }
      def latest_tags; end

      sig { returns(T::Array[Kuby::Docker::TimestampTag]) }
      def timestamp_tags; end

      sig { returns(T.nilable(Kuby::Docker::TimestampTag)) }
      def latest_timestamp_tag; end
    end

    class PackageList
      include Enumerable
      extend T::Sig
      extend T::Generic
      Elem = type_member { { fixed: Distro::PackageImpl } }

      sig { returns(T::Array[Distro::PackageImpl]) }
      attr_reader :packages

      sig { params(package_tuples: T::Array[[Symbol, T.nilable(String)]]).void }
      def initialize(package_tuples); end

      sig { params(name: Symbol).returns(T.nilable(Distro::PackageImpl)) }
      def [](name); end

      sig { params(name: Symbol, version: T.nilable(String)).void }
      def add(name, version = nil); end

      sig { params(name: String).void }
      def delete(name); end

      sig { override.params(block: T.proc.params(package: Distro::PackageImpl).void).void }
      def each(&block); end

      sig { returns(T::Boolean) }
      def empty?; end
    end

    class PackagePhase < Layer
      extend T::Sig
      Operation = T.type_alias { [Symbol, Symbol, T.nilable(String)] }

      sig { returns(T::Array[Operation]) }
      attr_reader :operations

      sig { params(environment: Kuby::Environment).void }
      def initialize(environment); end

      sig { params(package_name: Symbol, version: T.nilable(String)).void }
      def add(package_name, version = nil); end

      sig { params(package_name: Symbol).void }
      def remove(package_name); end

      sig { override.params(dockerfile: Kuby::Docker::Dockerfile).void }
      def apply_to(dockerfile); end

      sig { returns(Kuby::Docker::Distro) }
      def distro_spec; end

      sig { params(package_name: Symbol, version: T.nilable(String)).returns(Kuby::Docker::Distro::PackageImpl) }
      def get_package(package_name, version); end
    end

    class RemoteTags
      extend T::Sig

      sig { returns(::Docker::Remote::Client) }
      attr_reader :remote_client

      sig { returns(String) }
      attr_reader :image_url

      sig { params(remote_client: ::Docker::Remote::Client, image_url: String).void }
      def initialize(remote_client, image_url); end

      sig { returns(T::Array[String]) }
      def tags; end

      sig { returns(T::Array[String]) }
      def latest_tags; end

      sig { returns(T::Array[Kuby::Docker::TimestampTag]) }
      def timestamp_tags; end
    end

    class SetupPhase < Layer
      extend T::Sig
      DEFAULT_WORKING_DIR = T.let('/usr/src/app'.freeze, String)

      sig { params(base_image: String).returns(String) }
      attr_writer :base_image

      sig { returns(T.nilable(String)) }
      attr_reader :working_dir

      sig { params(working_dir: String).returns(String) }
      attr_writer :working_dir

      sig { returns(T.nilable(String)) }
      attr_reader :rails_env

      sig { params(rails_env: String).returns(String) }
      attr_writer :rails_env

      sig { returns(Docker::Spec) }
      attr_reader :docker_spec

      sig { params(environment: Environment, docker_spec: Docker::Spec).void }
      def initialize(environment, docker_spec); end

      sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile); end

      sig { returns(String) }
      def base_image; end

      sig { returns(String) }
      def default_base_image; end
    end

    class Spec
      extend T::Sig
      DEFAULT_DISTRO = T.let(:debian, Symbol)
      DEFAULT_APP_ROOT_PATH = T.let('.'.freeze, String)

      sig { returns(Kuby::Environment) }
      attr_reader :environment

      sig { returns(T.nilable(String)) }
      attr_reader :image_url_str

      sig { returns(T.nilable(String)) }
      attr_reader :registry_index_url_str

      sig { returns(T.nilable(String)) }
      attr_reader :app_root_path

      sig { returns(T.nilable(Kuby::Docker::AppImage)) }
      attr_reader :image

      sig { params(environment: Kuby::Environment).void }
      def initialize(environment); end

      sig { returns(Symbol) }
      def distro_name; end

      sig { params(image_url: String).void }
      def base_image(image_url); end

      sig { params(dir: String).void }
      def working_dir(dir); end

      sig { params(env: String).void }
      def rails_env(env); end

      sig { params(version: String).void }
      def bundler_version(version); end

      sig { params(path: String).void }
      def gemfile(path); end

      sig { params(path: String).void }
      def app_root(path); end

      sig { params(package_name: Symbol, version: T.nilable(String)).void }
      def package(package_name, version = nil); end

      sig { params(distro_name: Symbol).void }
      def distro(distro_name); end

      sig { params(path: String).void }
      def files(path); end

      sig { params(port: Integer).void }
      def port(port); end

      sig { params(url: String).void }
      def image_url(url); end

      sig { params(url: String).void }
      def registry_index_url(url); end

      sig { params(name: Symbol, layer: T.nilable(Layer), block: T.nilable(T.proc.params(df: Kuby::Docker::Dockerfile).void)).void }
      def use(name, layer = nil, &block); end

      sig do
        params(
          name: Symbol,
          layer: T.nilable(T.any(Layer, T::Hash[Symbol, T.untyped])),
          options: T::Hash[Symbol, T.untyped],
          block: T.nilable(T.proc.params(df: Dockerfile).void)
        ).void
      end
      def insert(name, layer = nil, options = {}, &block); end

      sig { params(name: Symbol).void }
      def delete(name); end

      sig { params(name: Symbol).returns(T::Boolean) }
      def exists?(name); end

      sig { params(block: T.nilable(T.proc.void)).returns(Kuby::Docker::Credentials) }
      def credentials(&block); end

      sig { void }
      def after_configuration; end

      sig { returns(Kuby::Docker::SetupPhase) }
      def setup_phase; end

      sig { returns(Kuby::Docker::PackagePhase) }
      def package_phase; end

      sig { returns(Kuby::Docker::BundlerPhase) }
      def bundler_phase; end

      sig { returns(Kuby::Docker::YarnPhase) }
      def yarn_phase; end

      sig { returns(Kuby::Docker::CopyPhase) }
      def copy_phase; end

      sig { returns(Kuby::Docker::AppPhase) }
      def app_phase; end

      sig { returns(Kuby::Docker::AssetsPhase) }
      def assets_phase; end

      sig { returns(Kuby::Docker::WebserverPhase) }
      def webserver_phase; end

      sig { returns(Kuby::Docker::Distro) }
      def distro_spec; end

      sig { returns(Kuby::Docker::LayerStack) }
      def layer_stack; end
    end

    class TimestampTag
      extend T::Sig
      FORMAT = T.let('%Y%m%d%H%M%S'.freeze, String)

      sig { params(str: T.nilable(String)).returns(T.nilable(Kuby::Docker::TimestampTag)) }
      def self.try_parse(str); end

      sig { returns(Kuby::Docker::TimestampTag) }
      def self.now; end

      sig { returns(Time) }
      attr_reader :time

      sig { params(time: Time).void }
      def initialize(time); end

      sig { returns(String) }
      def to_s; end

      sig { params(other: Kuby::Docker::TimestampTag).returns(T.nilable(Integer)) }
      def <=>(other); end

      sig { params(other: Kuby::Docker::TimestampTag).returns(T::Boolean) }
      def ==(other); end

      sig { returns(Integer) }
      def hash; end

      sig { params(other: Kuby::Docker::TimestampTag).returns(T::Boolean) }
      def eql?(other); end
    end

    class TimestampedImage < Image
      extend T::Sig

      sig do
        params(
          dockerfile: T.any(Dockerfile, T.proc.returns(Kuby::Docker::Dockerfile)),
          image_url: String,
          credentials: Kuby::Docker::Credentials,
          registry_index_url_str: T.nilable(String),
          main_tag: T.nilable(String),
          alias_tags: T::Array[String]
        ).void
      end
      def initialize(dockerfile, image_url, credentials, registry_index_url_str = nil, main_tag = nil, alias_tags = []); end

      sig { returns(Kuby::Docker::Image) }
      def new_version; end

      sig { returns(Kuby::Docker::Image) }
      def current_version; end

      sig { params(current_tag: T.nilable(String)).returns(Kuby::Docker::Image) }
      def previous_version(current_tag = nil); end

      sig { params(current_tag: T.nilable(String)).returns(Kuby::Docker::TimestampTag) }
      def previous_timestamp_tag(current_tag = nil); end

      sig { returns(Kuby::Docker::TimestampTag) }
      def latest_timestamp_tag; end

      sig do
        params(
          build_args: T::Hash[String, String],
          docker_args: T::Array[String],
          context: T.nilable(String),
          cache_from: T.nilable(String)
        ).void
      end
      def build(build_args = {}, docker_args = [], context: nil, cache_from: nil); end

      sig { params(tag: String).void }
      def push(tag); end

      sig { params(tag: String).void }
      def pull(tag); end

      sig { returns(T::Boolean) }
      def exists?; end

      sig { returns(::Docker::Remote::Client) }
      def remote_client; end

      sig { returns(T::Array[Kuby::Docker::TimestampTag]) }
      def timestamp_tags; end

      sig { returns(Kuby::Docker::LocalTags) }
      def local; end

      sig { returns(Kuby::Docker::RemoteTags) }
      def remote; end
    end

    class WebserverPhase < Layer
      extend T::Sig
      DEFAULT_PORT = T.let(8080, Integer)
      WEBSERVER_MAP = T.let({ puma: Puma }.freeze, T::Hash[Symbol, T.class_of(Webserver)])

      class Webserver
        abstract!

        extend T::Sig
        extend T::Helpers

        sig { returns(WebserverPhase) }
        attr_reader :phase

        sig { params(phase: WebserverPhase).void }
        def initialize(phase); end

        sig { abstract.params(dockerfile: Dockerfile).void }
        def apply_to(dockerfile); end
      end

      class Puma < Webserver
        sig { override.params(dockerfile: Dockerfile).void }
        def apply_to(dockerfile); end
      end

      sig { params(port: Integer).returns(Integer) }
      attr_writer :port

      sig { returns(T.nilable(Symbol)) }
      attr_reader :webserver

      sig { params(webserver: Symbol).returns(Symbol) }
      attr_writer :webserver

      sig { override.params(environment: Environment).void }
      def initialize(environment); end

      sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile); end

      sig { returns(Integer) }
      def port; end

      sig { returns(T.nilable(Symbol)) }
      def default_webserver; end
    end

    class YarnPhase < Layer
      extend T::Sig

      sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile); end

      sig { params(path: String).returns(String) }
      def ensure_trailing_delimiter(path); end
    end

    module Packages
      class ManagedPackage
        extend T::Sig

        sig { returns(Symbol) }
        attr_reader :name

        sig { returns(T::Hash[Symbol, String]) }
        attr_reader :names_per_distro

        sig { params(name: Symbol, names_per_distro: T::Hash[Symbol, String]).void }
        def initialize(name, names_per_distro); end

        sig { params(distro: Symbol).returns(String) }
        def package_name_for(distro); end

        sig { params(ver: String).returns(T.self_type) }
        def with_version(ver); end

        sig { returns(T::Boolean) }
        def managed?; end
      end

      class Nodejs < Package
        extend T::Sig

        sig { params(dockerfile: Dockerfile).void }
        def install_on_debian(dockerfile); end

        sig { params(dockerfile: Dockerfile).void }
        def install_on_alpine(dockerfile); end

        sig { returns(String) }
        def version; end

        sig { params(image: String, dockerfile: Dockerfile).void }
        def install_from_image(image, dockerfile); end
      end

      class Package
        abstract!

        extend T::Sig
        extend T::Helpers

        sig { returns(Symbol) }
        attr_reader :name

        sig { returns(T.nilable(String)) }
        attr_reader :version

        sig { params(name: Symbol, version: T.nilable(String)).void }
        def initialize(name, version = nil); end

        sig { params(ver: String).returns(T.self_type) }
        def with_version(ver); end

        sig { returns(T::Boolean) }
        def managed?; end
      end

      class SimpleManagedPackage
        extend T::Sig

        sig { returns(String) }
        attr_reader :name

        sig { params(name: T.any(String, Symbol)).void }
        def initialize(name); end

        sig { params(distro: Symbol).returns(String) }
        def package_name_for(distro); end

        sig { params(ver: String).returns(T.self_type) }
        def with_version(ver); end

        sig { returns(T::Boolean) }
        def managed?; end
      end

      class Yarn < Package
        extend T::Sig

        sig { params(name: Symbol, version: T.nilable(String)).void }
        def initialize(name, version = nil); end

        sig { params(dockerfile: Dockerfile).void }
        def install_on_debian(dockerfile); end

        sig { params(dockerfile: Dockerfile).void }
        def install_on_alpine(dockerfile); end

        sig { returns(String) }
        def url; end
      end
    end
  end

  module Kubernetes
    class BareMetalProvider < Provider
      extend T::Sig
      DEFAULT_STORAGE_CLASS = T.let('hostpath'.freeze, String)

      class Config
        extend ::KubeDSL::ValueFields
      end

      sig { returns(Config) }
      attr_reader :config

      sig { params(environment: Environment).void }
      def initialize(environment); end

      sig { params(block: T.proc.void).void }
      def configure(&block); end

      sig { returns(String) }
      def kubeconfig_path; end

      sig { returns(String) }
      def storage_class_name; end

      sig { void }
      def after_initialize; end
    end

    class DeployTask
      sig { returns(T.untyped) }
      attr_reader :deploy_task

      sig { params(kwargs: T.untyped).void }
      def initialize(**kwargs); end

      sig { params(kwargs: T.untyped).returns(T.untyped) }
      def run!(**kwargs); end

      sig { returns(T.untyped) }
      def logger; end

      sig { params(new_env: T.untyped).returns(T.untyped) }
      def with_env(new_env); end
    end

    class Deployer
      sig { returns(T.untyped) }
      attr_reader :environment

      sig { params(logdev: T.untyped).returns(T.untyped) }
      attr_writer :logdev

      sig { params(environment: T.untyped).void }
      def initialize(environment); end

      sig { returns(T.untyped) }
      def deploy; end

      sig { params(out: T.untyped, err: T.untyped).returns(T.untyped) }
      def with_pipes(out = STDOUT, err = STDERR); end

      sig { returns(T.untyped) }
      def logdev; end

      sig { returns(T.untyped) }
      def last_status; end

      sig { params(resources: T.untyped).returns(T.untyped) }
      def deploy_global_resources(resources); end

      sig { params(resources: T.untyped, ns: T.untyped).returns(T.untyped) }
      def deploy_namespaced_resources(resources, ns); end

      sig { returns(T.untyped) }
      def restart_rails_deployment_if_necessary; end

      sig { returns(T.untyped) }
      def provider; end

      sig { returns(T.untyped) }
      def namespace; end

      sig { returns(T.untyped) }
      def all_resources; end

      sig { returns(T.untyped) }
      def docker; end

      sig { returns(T.untyped) }
      def kubernetes; end

      sig { returns(T.untyped) }
      def cli; end
    end

    class DockerConfig
      extend ::KubeDSL::ValueFields

      sig { params(block: T.untyped).void }
      def initialize(&block); end

      sig { returns(T.untyped) }
      def serialize; end
    end

    class DockerDesktopProvider < Provider
      STORAGE_CLASS_NAME = 'hostpath'.freeze

      class Config
        extend ::KubeDSL::ValueFields
      end

      sig { returns(T.untyped) }
      attr_reader :config

      sig { params(block: T.untyped).returns(T.untyped) }
      def configure(&block); end

      sig { returns(T.untyped) }
      def kubeconfig_path; end

      sig { returns(T.untyped) }
      def storage_class_name; end

      sig { returns(T.untyped) }
      def after_initialize; end
    end

    class MissingDeploymentError < StandardError
    end

    class MissingProviderError < StandardError
    end

    class MissingPluginError < StandardError
    end

    class MissingResourceError < StandardError
    end

    class DuplicateResourceError < StandardError
    end

    class Manifest
      include Enumerable

      sig { params(resources: T.untyped).void }
      def initialize(resources); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def each(&block); end

      sig { params(kind: T.untyped, name: T.untyped).returns(T.untyped) }
      def find(kind, name); end

      sig { params(kind: T.untyped, name: T.untyped).returns(T.untyped) }
      def delete(kind, name); end

      sig { params(resource: T.untyped).returns(T.untyped) }
      def <<(resource); end

      sig { params(resource: T.untyped, kind: T.untyped, name: T.untyped).returns(T.untyped) }
      def matches?(resource, kind, name); end

      sig { returns(T.untyped) }
      def ensure_all_resources_unique!; end
    end

    class Provider
      sig { returns(T.untyped) }
      attr_reader :environment

      sig { params(environment: T.untyped).void }
      def initialize(environment); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def configure(&block); end

      sig { returns(T.untyped) }
      def setup; end

      sig { returns(T.untyped) }
      def after_configuration; end

      sig { returns(T.untyped) }
      def before_setup; end

      sig { returns(T.untyped) }
      def after_setup; end

      sig { params(manifest: T.untyped).returns(T.untyped) }
      def before_deploy(manifest); end

      sig { params(manifest: T.untyped).returns(T.untyped) }
      def after_deploy(manifest); end

      sig { returns(T.untyped) }
      def deploy; end

      sig { returns(T.untyped) }
      def rollback; end

      sig { returns(T.untyped) }
      def kubernetes_cli; end

      sig { returns(T.untyped) }
      def helm_cli; end

      sig { returns(T.untyped) }
      def kubeconfig_path; end

      sig { returns(T.untyped) }
      def deployer; end

      sig { returns(T.untyped) }
      def after_initialize; end

      sig { returns(T.untyped) }
      def spec; end
    end

    class RegistrySecret < ::KubeDSL::DSL::V1::Secret
      sig { params(block: T.untyped).void }
      def initialize(&block); end

      sig { returns(T.untyped) }
      def serialize; end
    end

    class Spec
      extend ::KubeDSL::ValueFields

      sig { returns(T.untyped) }
      attr_reader :environment

      sig { returns(T.untyped) }
      attr_reader :plugins

      sig { returns(T.untyped) }
      attr_reader :tag

      sig { params(environment: T.untyped).void }
      def initialize(environment); end

      sig { params(provider_name: T.untyped, block: T.untyped).returns(T.untyped) }
      def provider(provider_name = nil, &block); end

      sig { params(plugin_name: T.untyped, block: T.untyped).returns(T.untyped) }
      def configure_plugin(plugin_name, &block); end

      sig { params(plugin_name: T.untyped).returns(T.untyped) }
      def plugin(plugin_name); end

      sig { returns(T.untyped) }
      def after_configuration; end

      sig { returns(T.untyped) }
      def before_deploy; end

      sig { params(plugins: T.untyped).returns(T.untyped) }
      def check_dependencies!(plugins = @plugins); end

      sig { returns(T.untyped) }
      def after_deploy; end

      sig { params(only: T.untyped).returns(T.untyped) }
      def setup(only: []); end

      sig { params(tag: T.untyped).returns(T.untyped) }
      def deploy(tag = nil); end

      sig { returns(T.untyped) }
      def rollback; end

      sig { params(block: T.untyped).returns(T.untyped) }
      def namespace(&block); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def registry_secret(&block); end

      sig { returns(T.untyped) }
      def resources; end

      sig { returns(T.untyped) }
      def docker_images; end

      sig { returns(T.untyped) }
      def selector_app; end

      sig { returns(T.untyped) }
      def docker; end
    end
  end

  module Middleware
    class HealthCheck
      sig { returns(T.untyped) }
      attr_reader :app

      sig { params(app: T.untyped).void }
      def initialize(app); end

      sig { params(env: T.untyped).returns(T.untyped) }
      def call(env); end
    end
  end

  module Plugins
    class NginxIngress < ::Kuby::Plugin
      VERSION = '1.1.1'.freeze
      DEFAULT_PROVIDER = 'cloud'.freeze
      NAMESPACE = 'ingress-nginx'.freeze
      SERVICE_NAME = 'ingress-nginx-controller'.freeze
      SETUP_RESOURCES = [
        "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v#{VERSION}/deploy/static/provider/%{provider}/deploy.yaml"
      ].freeze

      class Config
        extend ::KubeDSL::ValueFields
      end

      sig { params(block: T.untyped).returns(T.untyped) }
      def configure(&block); end

      sig { returns(T.untyped) }
      def setup; end

      sig { returns(T.untyped) }
      def namespace; end

      sig { returns(T.untyped) }
      def service_name; end

      sig { returns(T.untyped) }
      def already_deployed?; end

      sig { returns(T.untyped) }
      def after_initialize; end

      sig { returns(T.untyped) }
      def kubernetes_cli; end
    end

    class System < ::Kuby::Plugin
    end

    module RailsApp
      class AssetCopyTask
        TIMESTAMP_FORMAT = '%Y%m%d%H%M%S'.freeze
        KEEP = 5

        sig { returns(T.untyped) }
        attr_reader :dest_path

        sig { returns(T.untyped) }
        attr_reader :source_path

        sig { params(to: T.untyped, from: T.untyped).void }
        def initialize(to:, from:); end

        sig { returns(T.untyped) }
        def run; end

        sig { returns(T.untyped) }
        def copy_new_assets; end

        sig { returns(T.untyped) }
        def delete_old_assets; end

        sig { params(ts: T.untyped).returns(T.untyped) }
        def try_parse_ts(ts); end

        sig { params(ts: T.untyped).returns(T.untyped) }
        def parse_ts(ts); end

        sig { returns(T.untyped) }
        def ts_dir; end

        sig { returns(T.untyped) }
        def current_dir; end
      end

      class Assets < ::Kuby::Plugin
        extend ::KubeDSL::ValueFields
        ROLE = 'assets'.freeze
        NGINX_IMAGE = 'nginx:1.9-alpine'.freeze
        NGINX_PORT = 8082
        NGINX_MOUNT_PATH = '/usr/share/nginx/assets'.freeze
        RAILS_MOUNT_PATH = '/usr/share/assets'.freeze

        sig { params(block: T.untyped).returns(T.untyped) }
        def configure(&block); end

        sig { params(ingress: T.untyped, hostname: T.untyped).returns(T.untyped) }
        def configure_ingress(ingress, hostname); end

        sig { returns(T.untyped) }
        def copy_task; end

        sig { params(block: T.untyped).returns(T.untyped) }
        def service(&block); end

        sig { params(block: T.untyped).returns(T.untyped) }
        def service_account(&block); end

        sig { params(block: T.untyped).returns(T.untyped) }
        def nginx_config(&block); end

        sig { params(block: T.untyped).returns(T.untyped) }
        def deployment(&block); end

        sig { returns(T.untyped) }
        def resources; end

        sig { returns(T.untyped) }
        def namespace; end

        sig { returns(T.untyped) }
        def selector_app; end

        sig { returns(T.untyped) }
        def role; end

        sig { returns(T.untyped) }
        def docker; end

        sig { returns(T.untyped) }
        def kubernetes; end

        sig { returns(T.untyped) }
        def image; end

        sig { returns(T.untyped) }
        def dockerfile; end

        sig { returns(T.untyped) }
        def docker_images; end
      end

      class AssetsImage < ::Kuby::Docker::Image
        sig { returns(T.untyped) }
        attr_reader :base_image

        sig do
          params(
            base_image: T.untyped,
            dockerfile: T.untyped,
            registry_index_url: T.untyped,
            main_tag: T.untyped,
            alias_tags: T.untyped
          ).void
        end
        def initialize(base_image, dockerfile, registry_index_url = nil, main_tag = nil, alias_tags = []); end

        sig { returns(T.untyped) }
        def new_version; end

        sig { returns(T.untyped) }
        def current_version; end

        sig { returns(T.untyped) }
        def previous_version; end

        sig do
          params(
            build_args: T.untyped,
            docker_args: T.untyped,
            context: T.untyped,
            cache_from: T.untyped
          ).returns(T.untyped)
        end
        def build(build_args = {}, docker_args = [], context: nil, cache_from: nil); end

        sig { params(tag: T.untyped).returns(T.untyped) }
        def push(tag); end

        sig { params(tag: T.untyped).returns(T.untyped) }
        def pull(tag); end

        sig { params(image: T.untyped).returns(T.untyped) }
        def duplicate_with_annotated_tags(image); end

        sig { params(tag: T.untyped).returns(T.untyped) }
        def annotate_tag(tag); end
      end

      module CRDB
      end

      class RewriteDbConfig
        sig { params(dockerfile: T.untyped).returns(T.untyped) }
        def apply_to(dockerfile); end
      end

      class Sqlite < ::Kuby::Plugin
        sig { returns(T.untyped) }
        attr_reader :environment

        sig { params(environment: T.untyped, _: T.untyped).void }
        def initialize(environment, *_); end

        sig { returns(T.untyped) }
        def after_configuration; end

        sig { params(_pod_spec: T.untyped).returns(T.untyped) }
        def configure_pod_spec(_pod_spec); end

        sig { returns(T.untyped) }
        def bootstrap; end

        sig { params(_user: T.untyped).returns(T.untyped) }
        def user(_user); end

        sig { params(_password: T.untyped).returns(T.untyped) }
        def password(_password); end

        sig { returns(T.untyped) }
        def name; end
      end
    end
  end

  module Utils
    sig { params(args: T.untyped).returns(T.untyped) }
    def self.which(*args); end

    class Table
      sig { returns(T.untyped) }
      attr_reader :headers

      sig { returns(T.untyped) }
      attr_reader :rows

      sig { params(headers: T.untyped, rows: T.untyped).void }
      def initialize(headers, rows); end

      sig { returns(T.untyped) }
      def to_s; end

      sig { params(values: T.untyped).returns(T.untyped) }
      def make_row(values); end

      sig { params(idx: T.untyped).returns(T.untyped) }
      def col_width_at(idx); end

      sig { returns(T.untyped) }
      def col_widths; end
    end

    module Which
      extend self

      sig { params(program: T.untyped, path: T.untyped).returns(T.untyped) }
      def which(program, path = ENV['PATH']); end
    end

    module SemVer
      sig { params(str: T.untyped).returns(T.untyped) }
      def self.parse_version(str); end

      sig { params(strs: T.untyped).returns(T.untyped) }
      def self.parse_constraints(*strs); end

      class Constraint
        OPERATOR_MAP = {
          '='  => :eq,
          '>'  => :gt,
          '>=' => :gteq,
          '<'  => :lt,
          '<=' => :lteq,
          '~>' => :waka
        }
        OPERATOR_INVERSE = OPERATOR_MAP.invert.freeze

        sig { returns(T.untyped) }
        attr_reader :operator

        sig { returns(T.untyped) }
        attr_reader :version

        sig { params(str: T.untyped).returns(T.untyped) }
        def self.parse(str); end

        sig { params(operator: T.untyped, version: T.untyped).void }
        def initialize(operator, version); end

        sig { returns(T.untyped) }
        def to_s; end

        sig { params(other_version: T.untyped).returns(T.untyped) }
        def satisfied_by?(other_version); end
      end

      class ConstraintSet
        sig { returns(T.untyped) }
        attr_reader :constraints

        sig { params(arr: T.untyped).returns(T.untyped) }
        def self.parse(*arr); end

        sig { params(constraints: T.untyped).void }
        def initialize(constraints); end

        sig { params(version: T.untyped).returns(T.untyped) }
        def satisfied_by?(version); end

        sig { returns(T.untyped) }
        def to_s; end
      end

      class Version
        include Comparable

        sig { returns(T.untyped) }
        attr_reader :major

        sig { returns(T.untyped) }
        attr_reader :minor

        sig { returns(T.untyped) }
        attr_reader :patch

        sig { params(str: T.untyped, default: T.untyped).returns(T.untyped) }
        def self.parse(str, default: 0); end

        sig { params(major: T.untyped, minor: T.untyped, patch: T.untyped).void }
        def initialize(major, minor, patch); end

        sig { returns(T.untyped) }
        def to_s; end

        sig { returns(T.untyped) }
        def to_a; end

        sig { params(other: T.untyped).returns(T.untyped) }
        def <=>(other); end
      end
    end
  end
end
