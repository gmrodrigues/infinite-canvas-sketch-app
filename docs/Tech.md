Especificação Técnica: Engine de Desenho em Canvas Infinito com Zig e Wacom

1. Visão Geral e Objetivos do Sistema

O uso do Zig (v0.13+) no desenvolvimento desta engine gráfica é uma escolha estratégica para garantir controle de memória determinístico e segurança de tipos sem o overhead de um coletor de lixo ou runtime pesado. A filosofia do Zig permite a manipulação direta de recursos de hardware com a precisão exigida por aplicações de baixa latência.

Pilares de Performance

* Baixa Latência (Input-to-Photon): Captura e processamento de eventos em nanosegundos para eliminar o atraso perceptível.
* Precisão Sub-pixel: Uso de tipos de ponto flutuante de 64 bits para representação espacial, garantindo integridade visual em níveis extremos de zoom.
* Escalabilidade Espacial: Gerenciamento eficiente de milhões de entidades vetoriais através de particionamento hierárquico.

A arquitetura proposta integra o hardware de entrada (Wacom) à renderização acelerada por GPU (via Sokol), mediada por uma estrutura de dados de Quadtree altamente otimizada.


--------------------------------------------------------------------------------


2. Gerenciamento de Input e Baixa Latência via C-ABI

Para capturar a fidelidade total de uma caneta Wacom, devemos contornar as abstrações de alto nível do sistema operacional e interagir diretamente com as APIs de baixo nível via C-ABI.

Integração Wintab e Libinput

Utilizaremos extern struct e @cImport para mapear as definições de C. No Linux (Libinput), os dados de eixos devem ser capturados através de assinaturas como:

* libinput_event_tablet_tool_get_tilt_x(event) -> f64
* libinput_event_tablet_tool_get_rotation(event) -> f64
* libinput_event_tablet_tool_get_pressure(event) -> f64

Polling e Concorrência de Baixa Latência

Para evitar jitter e manter a precisão sub-pixel, as coordenadas devem ser tratadas como f64 imediatamente após a captura.

* Comunicação Wait-Free: Para transferir dados da thread de polling para a thread de processamento/renderização sem travas (locks), implementaremos uma Fila SPSC (Single-Producer Single-Consumer) Lock-Free. Isso garante que o input nunca seja bloqueado por contenção de Mutex, mantendo o objetivo de latência mínima.


--------------------------------------------------------------------------------


3. Estabilização de Traço e Filtros de Suavização

O ruído inerente aos sensores de pressão e posição exige estabilização matemática antes da inserção na estrutura espacial.

Filtro Savitzky-Golay e Continuidade de Borda

Diferente de médias móveis simples que causam distorção em curvas fechadas, o filtro Savitzky-Golay utiliza convolução polinomial para preservar picos de pressão.

* Mitigação de Discontinuidades: Um desafio crítico deste filtro é a queda súbita para 0 nas bordas, causando saltos no início e fim do traço. Aplicaremos a estratégia de Extensão em Ordem Reversa (espelhamento dos primeiros e últimos pontos da amostragem) para fornecer contexto ao filtro e estabilizar as bordas do sinal.

Interpolação Bézier Cúbica em Zig

Pseudo-código para preenchimento de amostras entre eventos de alta velocidade:

pub const Point = struct { x: f64, y: f64, pressure: f32 };

pub fn interpolateBezier(p0: Point, p1: Point, p2: Point, p3: Point, t: f32) Point {
    const inv_t = 1.0 - t;
    const b0 = inv_t * inv_t * inv_t;
    const b1 = 3.0 * inv_t * inv_t * t;
    const b2 = 3.0 * inv_t * t * t;
    const b3 = t * t * t;

    return .{
        .x = b0 * p0.x + b1 * p1.x + b2 * p2.x + b3 * p3.x,
        .y = b0 * p0.y + b1 * p1.y + b2 * p2.y + b3 * p3.y,
        .pressure = b0 * p0.pressure + b1 * p1.pressure + b2 * p2.pressure + b3 * p3.pressure,
    };
}



--------------------------------------------------------------------------------


4. Arquitetura de Canvas Infinito e Particionamento Espacial

O gerenciamento de um espaço ilimitado depende de uma Quadtree recursiva para buscas e culling eficientes.

Lógica da Quadtree

A estrutura deve conter os campos boundary: Rectangle, capacity: usize, points: ArrayList(Point) e um sinalizador divided: bool.

* Gestão de Ciclo de Vida: Em cenários de movimento contínuo no canvas, a função clearQuadTree() será invocada para resetar a flag divided e reconstruir a árvore dinamicamente, garantindo que a estrutura reflita apenas os dados relevantes ao contexto atual.

Mitigação de Floating Point Drift

Para objetos situados em coordenadas massivas (ex: 1.000.000, 1.000.000), a precisão de f32 falha, causando trepidação visual.

1. View-Space Local: Coordenadas de mundo em f64 são convertidas para f32 apenas no espaço de visão da câmera antes do envio para a GPU.
2. Escalonamento (Scaling instead of Moving): Para objetos extremamente distantes que excedem a estabilidade mesmo em f64, utilizaremos o escalonamento descendente do objeto em relação à origem estática do jogador, simulando distância sem utilizar valores absolutos massivos.

Comparação de Particionamento

Método	Eficiência de Memória	Previsibilidade de I/O	Ideal Para
Quadtree	Alta (adapta-se à densidade)	Complexa (árvore recursiva)	Vetores e traços esparsos.
Tiling	Média (grades fixas)	Alta (carregamento por blocos)	Bitmaps e texturas densas.


--------------------------------------------------------------------------------


5. Stack de Gráficos: Backends para Zig 0.13+

A escolha do backend é vital para a manipulação de buffers de vértices dinâmicos gerados pelos traços.

* Sokol (sokol-gfx): Recomendado. Oferece compatibilidade estável com Zig 0.13, abstraindo APIs nativas (D3D11, Metal, Vulkan) com um footprint de memória mínimo. É ideal para aplicações onde os buffers de traços mudam a cada quadro.
* Mach (WebGPU): Excelente para o futuro, mas a API WebGPU ainda impõe restrições de sincronização que podem dificultar prefix sums em passes únicos de renderização.


--------------------------------------------------------------------------------


6. Persistência de Dados e Serialização de Alta Performance

A persistência do canvas deve ser compacta e segura contra ataques de profundidade.

Serialização MsgPack

Utilizaremos o formato binário MessagePack via zig-msgpack.

* Nota de Versão Obrigatória: Para o alvo Zig 0.13, o projeto deve utilizar a versão 0.0.6 da biblioteca zig-msgpack. Versões posteriores (0.14+) introduzem mudanças na interface std.io incompatíveis com o compilador 0.13.
* Segurança: O parser iterativo da biblioteca protege a engine contra "bombas de profundidade" (estruturas aninhadas maliciosas) que causariam stack overflow.

Exportação via Headless Rendering

A exportação em alta resolução (PNG/TGA) deve ocorrer em uma thread separada. Para evitar a fragmentação do heap principal da engine, utilizaremos um ArenaAllocator dedicado para o processo de renderização headless, liberando toda a memória da tarefa de uma só vez ao final da exportação.


--------------------------------------------------------------------------------


7. Melhores Práticas de Gerenciamento de Memória em Zig

Em Zig, a ausência de alocações ocultas permite uma arquitetura de memória "estilo TigerBeetle".

Filosofia de Alocação

* Static Subsystem Ownership: Em vez de um pool de objetos central, cada subsistema deve possuir estaticamente seus próprios arrays de nós. O chamador "traz seus próprios nós" (bring your own nodes), garantindo que a função insert() da Quadtree nunca realize alocações em tempo de execução.
* Checklist de Performance:
  * Panic Deterministíco: Uso de std.debug.panic para estados de falha lógica irrecuperável.
  * Arena vs GPA: ArenaAllocator para o ciclo de vida de um frame (renderização); GeneralPurposeAllocator para o estado persistente do canvas.
  * Segurança de Mutex: Uso de defer mutex.unlock() para evitar deadlocks em caminhos de erro.

Síntese Técnica

A stack Zig 0.13 + Sokol + Wacom provê a base necessária para ferramentas de produtividade visual de elite. Através da reconstrução dinâmica de Quadtrees, comunicação wait-free via SPSC e gestão estática de nós, a engine alcança a fluidez "zero-lag" necessária para o mercado profissional de artes e design.
