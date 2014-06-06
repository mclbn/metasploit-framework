require 'spec_helper'
require 'metasploit/framework/login_scanner/pop3'

describe Metasploit::Framework::LoginScanner::POP3 do
  subject(:scanner) { described_class.new }

  it_behaves_like 'Metasploit::Framework::LoginScanner::Base'
  it_behaves_like 'Metasploit::Framework::LoginScanner::RexSocket'

  context "#attempt_login" do
    
    let(:pub_blank) do
      Metasploit::Framework::Credential.new(
        paired: true,
        public: "public",
        private: ''
      )
    end
    context "Raised Exceptions" do
      it "Rex::ConnectionError should result in status :connection_error" do
        expect(scanner).to receive(:connect).and_raise(Rex::ConnectionError)
        result = scanner.attempt_login(pub_blank)

        expect(result).to be_kind_of(Metasploit::Framework::LoginScanner::Result)
        expect(result.status).to eq(:connection_error)
      end

      it "Timeout::Error should result in status :connection_error" do
        expect(scanner).to receive(:connect).and_raise(Timeout::Error)
        result = scanner.attempt_login(pub_blank)

        expect(result).to be_kind_of(Metasploit::Framework::LoginScanner::Result)
        expect(result.status).to eq(:connection_error)
      end

      it "EOFError should result in status :connection_error" do
        expect(scanner).to receive(:connect).and_raise(EOFError)
        result = scanner.attempt_login(pub_blank)

        expect(result).to be_kind_of(Metasploit::Framework::LoginScanner::Result)
        expect(result.status).to eq(:connection_error)
      end
    end
    
    context "Open Connection" do
      let(:sock) {double('socket')}
      
      before(:each) do
        sock.stub(:shutdown)
        sock.stub(:close)
        expect(scanner).to receive(:connect)
        scanner.stub(:sock).and_return(sock)
                
      end
      
      it "Server returns +OK" do
        expect(sock).to receive(:get_once).exactly(3).times.and_return("+OK")
        expect(sock).to receive(:put).with("USER public\r\n").once.ordered
        expect(sock).to receive(:put).with("PASS \r\n").once.ordered
        
        result = scanner.attempt_login(pub_blank)

        expect(result).to be_kind_of(Metasploit::Framework::LoginScanner::Result)
        expect(result.status).to eq(:success)
        
      end
      
      it "Server Returns Something Else" do
        sock.stub(:get_once).and_return("+ERROR")
        
        result = scanner.attempt_login(pub_blank)

        expect(result).to be_kind_of(Metasploit::Framework::LoginScanner::Result)
        expect(result.status).to eq(:failed)
        expect(result.proof).to eq("+ERROR")
        
      end
    end
    
  end
end
