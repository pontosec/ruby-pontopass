#encoding: UTF-8
# = Using RDoc # # :title: Pontopass SDK
#requires
require 'net/http'
require 'json'
require 'cgi'
#require 'rack'

 # <b> Descrição </b> 
 #
 # A classe pontopassAuth é utilizada para conexão e autenticação no sistema Pontopass.
 # O Pontopass é um sistema para fácil implementação de autenticação em duas etapas, ou autenticação forte.
 # Para utilizar o sistema, é necessário primeiro se cadastrar em https://pontopass.com.
 # Para maiores detalhes, acesse https://pontopass.com e https://pontosec.com.
class PontopassAuth
	# atributo que contem o user agent. Atribuido automaticamente pelo header 'HTTP_USER_AGENT' 
	attr_accessor :user_agent
	# atributo que contem o user agent. Atribuido automaticamente pelo header 'REMOTE_ADDRESS' 
	attr_accessor :user_ip
	# numero da session do usuário. Atribuído automaticamente após a execução do método init
	attr_accessor :user_session

	# atributos privados
	@@api_server = "api.pontopass.com" #"localhost:3000"
	@@frameurl = "https://widget.pontopass.com/v1.0.0/widget"
	@@token_type = { 1 => "telefone", 2 => "sms", 3 => "app", 4 => "token"}

	#status da sessão atual
	@status = nil
	#url de retorno para o widget
	@return_url = nil
	#tipo de retorno desejado para o Widget (GET/POST)
	@return_method = "POST"

	#mensagens de status
	@@statustxt =  {0 => "Sucesso",
				20 => "Erro ao iniciar",
				30 => "Chave inv&Atilde;&iexcl;lida",
				100 => "Sess&Atilde;&pound;o criada",
				110 => "Novo dispositivo permitido para o usu&Atilde;&iexcl;rio",
				115 => "Sem dispositivo cadastrado, permitir acesso",
				150 => "Erro ao gravar session",
				151 => "Erro ao gravar usu&Atilde;&iexcl;rio - Usu&Atilde;&iexcl;rio j&Atilde;&iexcl; existe",
				152 => "Erro ao gravar usu&Atilde;&iexcl;rio",
				153 => "Erro ao deletar usu&Atilde;&iexcl;rio",
				155 => "IP e/ou User Agent incorreto(s)",
				210 => "Erro de grava&Atilde;&sect;&Atilde;&pound;o no cache",
				220 => "Erro Interno",
				310 => "Erro Interno",
				320 => "Erro Interno",
				400 => "Usu&Atilde;&iexcl;rio n&Atilde;&pound;o encontrado",
				405 => "Erro Interno",
				410 => "Sess&Atilde;&pound;o n&Atilde;&pound;o encontrada",
				411 => "Aplica&Atilde;&sect;&Atilde;&pound;o n&Atilde;&pound;o corresponde a session",
				413 => "Session inv&Atilde;&iexcl;lida",
				415 => "Dispositivo n&Atilde;&pound;o encontrado",
				420 => "M&Atilde;&copy;todo n&Atilde;&pound;o encontrado",
				422 => "Aplica&Atilde;&sect;&Atilde;&pound;o n&Atilde;&pound;o encontrada",
				425 => "M&Atilde;&copy;todo n&Atilde;&pound;o encontrado",
				440 => "Erro Interno",
				450 => "Erro Interno",
				490 => "Sem dispositivo cadastrado, bloquear acesso",
				492 => "Telefone invalido",
				495 => "Novo m&Atilde;&copy;todo inserido",
				510 => "Erro na Liga&Atilde;&sect;&Atilde;&pound;o",
				520 => "Erro no SMS",
				530 => "Erro no mobile Token",
				540 => "Erro no Aplicativo Mobile",
				600 => "Sem cr&Atilde;&copy;ditos dispon&Atilde;&shy;veis",
				710 => "Erro no Login",
				720 => "IP Inv&Atilde;&iexcl;lido",
				800 => "Aguardando resposta",
				810 => "Login bloqueado - SMS",
				820 => "Login bloqueado - Mobile Token",
				830 => "Login bloqueado - Chamada n&Atilde;&pound;o atendida",
				840 => "Login bloqueado - Push / Telefone",
				999 => "Sessão não iniciada ou não definida"}


	 # <b>Descrição</b> 
	 #
     # - Gera a classe com os dados de autenticação. 
     #
     # <b>Parâmetros</b>
     # 
     # <b>Entrada</b>
     # api_id:: ID de autenticação da API Pontopass
     # api_key:: Chave para acesso na API Pontopass
    def initialize(api_id, api_key)
    	@api_id = api_id
		@api_key = api_key
		@user_agent = ENV['HTTP_USER_AGENT']
		@user_ip = ENV['REMOTE_ADDR']
		@user_remember = 0
		@integration_type = 1
	end

	 # <b>Descrição </b> 
	 #
     # Uso interno para solicitações http
    protected 
    def send(path) 
		#define URL para acesso
		url = "https://" + @@api_server + '/' + path + '/json'
		uri = URI.parse(url)
		#gera a conexao http
		http = Net::HTTP.new(uri.host, uri.port)
		#define com SSL
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		request = Net::HTTP::Get.new(uri.request_uri)
		request.basic_auth(@api_id,@api_key)
		response = http.request(request)
		#se a resposta nao for 200, retorna o codigo de erro
		if (not response) or (response.code != "200")
			@status = response ? response.code : 999
			return 999
		end
		#converte o retorno em json e obtem seu status
		decode = JSON.parse(response.body)
		@status = decode["status"] ? decode["status"] : 999
		decode
	end
  
     # <b> Descrição</b> 
     #
     # Exibe a descrição em texto do último status ocorrido
     #
     # <b>  Parâmetros</b>
     # 
     # <b>Saída</b>
     # StatusString::texto descritivo do ultimo status
    public
    def lastStatus
		@@statustxt[@status];
	end

	 # <b>Descrição</b>
	 #
     # Inicializa uma nova session para o usuário com Ip e user agent determinados automaticamente.
     #
     # <b>Parâmetros</b>
     # 
     # <b>Entrada</b>
     # username:: Login do usuário
     # use_widget::  false: Utiliza API; true: Utiliza Widget JavaScript <i>(default = false)</i>
     # save_session:: false: não grava a session; true: grava a session no database<i>(default = false)</i> 
     #
     # <b>Saída</b>
     # Status 0:: OK
     # Status 999:: ERROR
	def init(username,use_widget=nil,user_remember=nil,user_ip=nil,user_agent=nil)
		@integration_type = use_widget ? 1 : 0
		@user_remember = user_remember ? 1 : 0
		if user_ip
			@user_ip = user_ip
		end
		if user_agent 
			@user_agent = user_agent
		end
		@user = username

		ret = send("init/#{username}/#{@integration_type}/#{@user_remember}/#{@user_ip}/#{CGI::escape(@user_agent)}");
		
		if(ret["session"])
			@user_session = ret["session"]
		end
		ret["status"] ? ret["status"] : 999
	end
    
     # <b>Descrição</b>
     #
     # Lista os dispositivos do usuario da session inicializada.
     #
     # <b>Requisitos</b>
     #
	 # Session válida existente
	 #
	 # <b>Parâmetros</b>
	 #
     # <b>Saída</b>
     # NULL:: caso não obtenha os dados corretamente
     # JSON:: métodos de login do usuário.
     # <b>Campos:</b>
     # <tt>{"description":"descrição",
     # "id":"Id do método",
     # "number":"número de telefone",
     # "token_type":"tipo de método"}</tt>
	def listMethods()
		@user_session ? send("list/#{@user_session}/#{@user_ip}/#{CGI::escape(@user_agent)}") : false 
	end
   
     # <b>Descrição</b>
     #
     # Solicita a autenticação com o método desejado
     #
     # <b>Requisitos</b>
     #
	 # Session válida inicializada
	 #
	 # Métodos para autenticação listados
	 #
	 # <b>Parâmetros</b>
	 #
	 # <b>Entrada</b>
	 # methodID:: ID do método, obtido no array recebido do ListMethods 
     # <b>Saída</b>
     # statusCode:: Código do status do processo
	def ask(device_id) 
		if @user_session
			ret = send("ask/#{@user_session}/#{device_id.to_s}/#{@user_ip}/#{CGI::escape(user_agent)}")
			ret["status"] ? ret["status"] : 999
		else 
			return 999;
		end
   	end


   	 # <b>Descrição</b>
   	 #
     # Valida a autenticação desejada
     #
     # <b>Requisitos</b>
     #
	 # Autenticação solicitada
	 #
	 # <b>Parâmetros</b>
	 #
	 # <b>Entrada</b>
	 # answer:: Codigo para validação
	 # token_type:: tipo de device solicitado no método ask
	 #
     # <b>Saída</b>
     # statusCode:: Código do status do processo
	def validate(answer,token_type)
		if(@user_session)
			url = "validate/#{@@token_type[token_type].to_s}/#{@user_session}/#{answer}/#{@user_ip}/#{CGI::escape(user_agent)}"
			ret = send(url)
			ret["status"]# ? ret["status"] : 999
		else
			999
		end
   end
   
     # <b>Descrição</b>
     #
     # Gera o widget do pontopass: <b> BETA </b>
     #
	 # <b>Parâmetros</b>
	 #
	 # <b>Entrada</b>
	 # return_url:: url onde o widget devera ser gerado
	 # h:: altura do widget  (default = 500px)
	 # w:: largura do widget (default = 500px)
	 # return_method:: GET ou POST (default = POST)
	 # post:: Parâmetros Post (default = nil)
	 # get:: Parâmetros Get (default = nil)
	 #
     # <b>Saída</b>
     # frame:: Frame contendo o widget javascript, no tamanho informado
	def widget(return_url, h=500, w=500, return_method="POST", post=nil, get=nil)
		postparams = "" 
		getparams = ""
		if post
				post.each do |key,value| 
					postparams += "post_$#{key}=#{CGI::escape(value)}&"
			end
		end
		if get 
				get.each do |key,value| 
					getparams += "get_$#{key}=#{CGI::escape(value)}&"
			end
		end
		url = "#{@frameurl}?#pontopass_save=#{@user_remember}&pontopass_url=#{CGI::escape(@return_url)}&pontopass_sess=#{@user_session}&#{postparams}#{getparams}"
		"<iframe src='#{url}' width='#{w}' height='#{h}' frameBorder='0'></iframe>"
	end

     # <b>Descrição</b>
     #
     # Checa o status e validade da sessão atual. Utilizado para métodos phone e mobile push.
     #
	 # <b>Parâmetros<b>
	 #
	 # <b>Entrada</b>
	 # login:: login do usuario 
     # <b>Saída</b>
     # status:: true ou false para autenticação da sessão atual
	def checkAnswer(login)
		if not @user_session 
			if (params['pontopass_session'])
				@user_session = params['pontopass_session']
			end
		end
		if not @user_session
			ret = send("auth/#{params['pontopass_session']}/#{@user_ip}/#{CGI::escape(@user_agent)}")
			if ret["login"]
				ret["login"] == login
			else
				false
			end
		else
			false
		end
	end

	 # <b>Descrição</b>
	 #
     # Checa o status e validade da sessão atual. Utilizado para métodos phone e mobile push.
     #
	 # <b>Parâmetros</b>
	 #
     # <b>Saída</b>
     # status:: true ou false para autenticação da sessão atual
 	def status()	
		ret = send("status/#{@user_session}/#{@user_ip}/#{CGI::escape(@user_agent)}")
		ret["status"] ? ret["status"] : 999
	end
end

 # <b>Descrição</b>
 #
 # A classe PontopassUser é utilizada para gerenciamento dos dados de usuários no Pontopass.
 # O Pontopass é um sistema para fácil implementação de autenticação em duas etapas, ou autenticação forte.
 # Para utilizar o sistema, é necessário primeiro se cadastrar em https://pontopass.com.
 # Para maiores detalhes, acesse https://pontopass.com e https://pontosec.com.
class PontopassUser < PontopassAuth

	 # <b>Descrição</b>
	 #
     # Cria um novo login de usuário no Pontopass
     #
	 # <b>Parâmetros</b>
	 #
	 # <b>Entrada</b>
	 # login:: login do usuário 
	 # name:: nome de exibição do usuário (default = login)
     # <b>Saída</b>
     # statusCode:: Código do status da criação
	def create(login,name="")
		ret = send("manage/user/insert/#{@login}/#{CGI::escape(name)}")
		ret["status"]
	end

	 # <b>Descrição</b>
	 #
     # Remove um usuário do Pontopass
     #
	 # <b>Parâmetros</b>
	 #
	 # <b>Entrada<b>
	 # login:: login do usuário 
     # <b>Saída</b>
     # statusCode:: Código do status da remoção
	def delete(login) 
		ret = send("manage/user/delete/#{login}")
		ret["status"]
	end

	 # <b>Descrição</b>
	 #
     # Verifica se o Usuário informado existe
     #
	 # <b>Parâmetros</b>
	 #
	 # <b>Entrada</b>
	 # login:: login do usuário 
     # <b>Saída</b>
     # Status:: 0, caso o usuário exista
	def check(login)
		ret = send("manage/user/check/#{login}")
		ret["status"].to_i
	end

	 # <b>Descrição</b>
	 #
     # Insere um dispositivo de autenticação
     #
	 # <b>Parâmetros</b>
	 #
	 # <b>Entrada</b>
	 #
	 # login:: login do usuário 
	 # type:: tipo de autenticação
	 # phone:: telefone
	 # desc:: descrição do dispositivo (default = nil)
     # <b>Saída</b>
     # statusCode:: Código do status da criação
	def insertDevice(login,type,phone,desc=null)
		ret = send("manage/method/insert/#{login}/#{type}/#{phone}/#{desc}")
		ret["status"]
	end

	 # <b>Descrição</b>
	 #
     # Remove um dispositivo de autenticação
     #
	 # <b>Parâmetros</b>
	 #
	 # <b>Entrada</b>
	 # login:: login do usuário 
	 # methodid::  id do método de autenticação
     # <b>Saída</b>
     # statusCode:: Código do status da remoção
	def deleteDevice(login, methodid) 
		ret = send("manage/method/delete/#{login}/#{methodid}")
		ret["status"]
	end

	 # <b>Descrição</b>
	 #
     # Lista os dispositivos para autenticação do usuário
     #
	 # <b>Parâmetros</b>
	 #
	 # <b>Entrada</b>
	 # login:: login do usuário 
     # <b>Saída</b>
     # JSON:: array json com os métodos de autenticação do usuário
	def listMethods(login) 
		ret = send("manage/method/list/#{login}")
		ret
	end	

	 # <b>Descrição</b>
	 #
     # Verifica se o ID do dispositivo informado pertence ao usuário
     #
	 # <b>Parâmetros</b>
	 #
	 # <b>Entrada</b>
	 # login:: login do usuário 
	 # metho_id:: ID do dispositivo do usuário
     # <b>Saída</b>
     # Status:: 0, caso o dispositivo pertença ao usuário
	def checkMethod(login,method_id)
		ret = send("manage/method/check/#{login}/#{method_id.to_S}")
		ret["status"].to_i
	end
end