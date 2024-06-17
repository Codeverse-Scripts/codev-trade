let offered = [];
let accepted = false;
let times = 0;
let imgLocation = null;

const convertValue = (value, oldMin, oldMax, newMin, newMax) => {
    const oldRange = oldMax - oldMin
    const newRange = newMax - newMin
    const newValue = ((value - oldMin) * newRange) / oldRange + newMin
    return newValue
}

$(function(){
    let inventory = null;
    window.addEventListener("message", function(e){
        data = e.data;

        if(data.action == "setItems"){
            imgLocation = data.imgLocation;
            inventory = Object.values(data.items);
            inventory = inventory.filter(function (el) {
                return el != null;
            });
            refreshInv(inventory);
            $("body").fadeIn(200);
            $(".seconds").text(data.acceptTime);
            times = data.acceptTime;
        }
        
        if(data.action == "refreshOfferedItems"){
            $(".their-offer .boxes").html(data.html);
            $(".their-offer .boxes .box").removeClass("added");
        }
        
        if(data.action == "sendTime"){
            $(".seconds").text(data.time);
            $(".loading .top").css("stroke-dashoffset", convertValue(data.time, 0, times, 0, 315));
            if (data.time == 3){
                $(".decline-btn").addClass("accept");
            }
        }
        
        if(data.action == "end"){
            $("body").fadeOut(200)
            $(".item-box").remove(); 
            $(".accept-box").removeClass("accept");
            $(".btn").removeClass("accept");
            $(".dropped").removeAttr("data-item");
            $(".dropped").removeClass("dropped");
            accepted = false;
            offered = [];
        }
        
        if(data.action == "sendStatus"){
            if (data.status){
                $(".their-offer .accept-box").addClass("accept");
            }else{
                $(".their-offer .accept-box").removeClass("accept");
            }
        }
    })

    $(document).on("click", ".decline-btn", function(){
        $("body").fadeOut(200)
        $(".item-box").remove();
        $(".accept-box").removeClass("accept");
        $(".btn").removeClass("accept");
        $(".dropped").removeAttr("data-item");
        $(".dropped").removeClass("dropped");
        accepted = false;
        offered = [];
        $.post(`https://${GetParentResourceName()}/cancelTrade`)
    })

    $(document).on("click", ".accept-btn", function(){
        if (!accepted) {
            $(".accept-btn").addClass("accept");
            $(".your-offer .accept-box").addClass("accept");
            $(".accept-btn").html("ACCEPTED");
            accepted = true;
        }

        $.post(`https://${GetParentResourceName()}/acceptOffer`, JSON.stringify({accepted: accepted}))
    })
    
    $(document).on("click", ".your-offer .added", function(e){
        if (!accepted){
            e.preventDefault();
            $(this).parent().removeAttr("data-item");
            $(this).remove();
    
            let item = $(this).data("item");
            offered.forEach((itemName, i) => {
                if(itemName.name == item){
                    inventory.push(itemName);
                    offered.splice(i, 1);
                }
            });
            refreshInv(inventory);
            $.post(`https://${GetParentResourceName()}/refreshItems`, JSON.stringify({items: offered, html: $(".your-offer .boxes").html()}))
        }
    })

    $(".your-offer .box").droppable({
        drop: function(event, ui) {
            $(this).removeClass("over");
            if (accepted) return;
            if ($(this).find(".item-box").length > 0) {
                return;
            }

            $(this).find(".item-box").remove();
            $(this).append(ui.draggable);
            $(this).find(".item-box").addClass("added");
            $(".your-offer .box").removeClass("over");

            let item = $(this).find(".item-box").data("item");
            
            inventory.forEach((itemName, i) => {
                if(itemName.name == item){
                    inventory.splice(i, 1);
                    offered.push(itemName);
                }
            });

            refreshInv(inventory);
            $.post(`https://${GetParentResourceName()}/refreshItems`, JSON.stringify({items: offered, html: $(".your-offer .boxes").html()}))
        },
        over: function(event, ui) {
            $(this).addClass("over");
        },
        out: function(event, ui) {
            $(this).removeClass("over");
        }
    });
})

function table_size(tlb){
    var size = 0, key;
    for (key in tlb) {
        if (tlb.hasOwnProperty(key)) size++;
    }
    return size;
}

function refreshInv(items){
    $(".inventory .boxes .box").remove();
    let itemCount = table_size(items);
            
    for (let i = 0; i < itemCount; i++) {
        let item = items[i];
        if (item){
            $(".inventory .boxes").append(`
            <div class="box">
                <div class="item-box ui-widget-content" data-item="${item.name}">
                    <div class="amount">${item.count}x</div>
                    <div class="item-img"><img src="${imgLocation+item.image}"></div>
                    <div class="item-name">${item.label}</div>
                </div>
            </div>
            `)

            $(".inventory .item-box").draggable({
                stop: function (e, ui) {
                    const $target = $(e.target)

                    $target.css({
                        top: "0",
                        left: "0",
                        position: "relative",
                    })
                },
            });
        }
    }

    for (let i = 0; i < 25 - itemCount; i++) {
        $(".inventory .boxes").append(`
            <div class="box"></div>
        `)
    }
}